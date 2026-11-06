#!/usr/bin/env python3
"""Exercise persisted auth across separate Android processes without uninstalling."""
import argparse
import base64
import json
import os
from pathlib import Path
import subprocess
from urllib.parse import urlparse

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--save-defines', type=Path, required=True)
parser.add_argument('--restore-defines', type=Path, required=True)
parser.add_argument('--log-directory', type=Path, required=True)
parser.add_argument('--serial', default='emulator-5554')
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
args.log_directory.mkdir(mode=0o700, parents=True, exist_ok=True)
args.log_directory.chmod(0o700)
results = []
adb = ['adb', '-s', args.serial]
build_log = args.log_directory / 'build.log'
build_log.touch(mode=0o600)
build_log.chmod(0o600)
# Flutter generates native plugin registration for the integration entrypoint.
# Run sequentially: another Flutter build can rewrite this generated file.
with build_log.open('w') as output:
    prepared = subprocess.run(['flutter', 'build', 'apk', '--debug',
        '--target', 'integration_test/usp_session_test.dart',
        f'--dart-define-from-file={args.save_defines.resolve()}'], cwd=root,
        stdout=output, stderr=subprocess.STDOUT)
if prepared.returncode:
    raise SystemExit(prepared.returncode)
for phase, path in [('save', args.save_defines), ('restore', args.restore_defines)]:
    if path.stat().st_mode & 0o077:
        parser.error('Defines must be private (chmod 600).')
    values = json.loads(path.read_text())
    if urlparse(values.get('API_BASE_URL', '')).hostname != '127.0.0.1':
        parser.error('Only the isolated loopback API is allowed.')
    if values.get('E2E_SESSION_PHASE') != phase:
        parser.error('Incorrect phase in defines.')
    encoded = ','.join(base64.b64encode(f'{k}={v}'.encode()).decode()
                       for k, v in values.items())
    log = args.log_directory / f'{phase}.log'
    log.touch(mode=0o600)
    log.chmod(0o600)
    with log.open('w') as output:
        result = subprocess.run(['./gradlew', ':app:assembleDebug',
            ':app:assembleDebugAndroidTest',
            f'-Ptarget={root}/integration_test/usp_session_test.dart',
            f'-Pdart-defines={encoded}'], cwd=root / 'android',
            env=os.environ.copy(), stdout=output, stderr=subprocess.STDOUT)
        if result.returncode:
            raise SystemExit(result.returncode)
        # connectedDebugAndroidTest and flutter test uninstall after each run.
        # Install with -r and invoke instrumentation directly to retain prefs.
        for apk in ['build/app/outputs/apk/debug/app-debug.apk',
                    'build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk']:
            subprocess.run(adb + ['install', '-r', str(root / apk)],
                check=True, stdout=output, stderr=subprocess.STDOUT)
    instrumentation_log = args.log_directory / f'{phase}-instrumentation.log'
    instrumentation_log.touch(mode=0o600)
    instrumentation_log.chmod(0o600)
    with instrumentation_log.open('w') as output:
        result = subprocess.run(adb + ['shell', 'am', 'instrument', '-w', '-e',
            'class', 'com.br.spotecnologia.uniuspapp.NativeSessionTest',
            'com.br.spotecnologia.uniuspapp.test/androidx.test.runner.AndroidJUnitRunner'],
            stdout=output, stderr=subprocess.STDOUT)
    transcript = instrumentation_log.read_text()
    passed = result.returncode == 0 and 'OK (1 test)' in transcript
    results.append({'phase': phase, 'runner_exit': result.returncode,
                    'instrumentation_passed': passed})
    (args.log_directory / 'results.json').write_text(json.dumps(results, indent=2))
    print(f'Native session {phase}: {"PASS" if passed else "FAIL"} '
          f'(adb exit {result.returncode})', flush=True)
    if not passed:
        raise SystemExit(1)
