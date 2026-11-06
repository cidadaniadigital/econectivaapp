#!/usr/bin/env python3
"""Validate the real Android external attachment viewer on isolated local data."""
import argparse
import base64
import json
import os
from pathlib import Path
import subprocess
from urllib.parse import urlparse

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--defines', type=Path, required=True)
parser.add_argument('--log', type=Path, required=True)
parser.add_argument('--serial', default='emulator-5554')
args = parser.parse_args()
if args.defines.stat().st_mode & 0o077:
    parser.error('Defines must be private (chmod 600).')
values = json.loads(args.defines.read_text())
if urlparse(values.get('API_BASE_URL', '')).hostname != '127.0.0.1':
    parser.error('Only the isolated loopback preview is allowed.')
root = Path(__file__).resolve().parents[1]
args.log.touch(mode=0o600)
args.log.chmod(0o600)
target = 'integration_test/usp_attachment_open_test.dart'
encoded = ','.join(base64.b64encode(f'{k}={v}'.encode()).decode()
                   for k, v in values.items())
for port in ['8082', '8774']:
    subprocess.run(['adb', '-s', args.serial, 'reverse', 'tcp:'+port, 'tcp:'+port], check=True)
with args.log.open('w') as output:
    build = subprocess.run(['flutter', 'build', 'apk', '--debug', '--target', target,
        f'--dart-define-from-file={args.defines.resolve()}'], cwd=root,
        stdout=output, stderr=subprocess.STDOUT)
    if build.returncode:
        raise SystemExit(build.returncode)
    result = subprocess.run(['./gradlew', ':app:connectedDebugAndroidTest',
        '-Pandroid.testInstrumentationRunnerArguments.class=com.br.spotecnologia.uniuspapp.NativeAttachmentOpenTest',
        f'-Ptarget={root}/{target}', f'-Pdart-defines={encoded}'],
        cwd=root/'android', env=os.environ.copy(), stdout=output, stderr=subprocess.STDOUT)
print(f'External attachment validation exit: {result.returncode}', flush=True)
raise SystemExit(result.returncode)
