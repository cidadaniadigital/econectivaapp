#!/usr/bin/env python3
"""Run the Android DocumentsUI regression test against the isolated preview.

The defines JSON is local and must never be committed. The runner prepares
three synthetic documents under Download/USP_Validation on the emulator.
"""
import argparse
import base64
import json
import os
from pathlib import Path
import subprocess
import struct
import tempfile
import zlib
from urllib.parse import urlparse

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--defines', type=Path, required=True)
parser.add_argument('--log', type=Path, required=True)
parser.add_argument('--serial', default='emulator-5554')
args = parser.parse_args()
if args.defines.stat().st_mode & 0o077:
    parser.error('The defines file must be private (chmod 600).')
values = json.loads(args.defines.read_text())
if urlparse(values.get('API_BASE_URL', '')).hostname != '127.0.0.1':
    parser.error('This writing test requires the loopback preview API.')
root = Path(__file__).resolve().parents[1]
adb = ['adb', '-s', args.serial]
subprocess.run(adb + ['shell', 'mkdir', '-p', '/sdcard/Download/USP_Validation'], check=True)
def png_chunk(kind, data):
    return struct.pack('!I', len(data)) + kind + data + struct.pack('!I', zlib.crc32(kind + data) & 0xffffffff)
with tempfile.TemporaryDirectory(prefix='usp-native-fixtures-') as folder:
    documents = {'usp-plan-note.txt': 'Anexo sintético USP. Sem dados pessoais.\n'.encode()}
    for name, color in [('usp-plan-cover.png', bytes([32,144,176])),
                        ('usp-plan-cover-2.png', bytes([224,112,48]))]:
        documents[name] = (bytes([137,80,78,71,13,10,26,10]) +
            png_chunk(b'IHDR', struct.pack('!2I5B',320,180,8,2,0,0,0)) +
            png_chunk(b'IDAT', zlib.compress((bytes([0])+color*320)*180)) + png_chunk(b'IEND',b''))
    for name, data in documents.items():
        source = Path(folder) / name
        source.write_bytes(data)
        target = '/sdcard/Download/USP_Validation/' + name
        subprocess.run(adb + ['push', str(source), target], check=True, stdout=subprocess.DEVNULL)
        subprocess.run(adb + ['shell','am','broadcast','-a','android.intent.action.MEDIA_SCANNER_SCAN_FILE',
                             '-d','file://' + target], check=True, stdout=subprocess.DEVNULL)
for port in ['8082', '8774']:
    subprocess.run(adb + ['reverse', 'tcp:' + port, 'tcp:' + port], check=True)

encoded = ','.join(base64.b64encode(f'{key}={value}'.encode()).decode()
                   for key, value in values.items())
command = ['./gradlew', ':app:connectedDebugAndroidTest',
           '-Pandroid.testInstrumentationRunnerArguments.class=com.br.spotecnologia.uniuspapp.NativeFilePickerTest',
           f'-Ptarget={root}/integration_test/usp_native_files_test.dart',
           f'-Pdart-defines={encoded}']
# Avoid exposing credentials through tool output or a shell command string.
args.log.touch(mode=0o600)
args.log.chmod(0o600)
with args.log.open('w') as log:
    # Generate registration for integration_test after any preceding web build.
    # Flutter builds and this Gradle invocation must run sequentially.
    build = subprocess.run(['flutter', 'build', 'apk', '--debug', '--target',
        'integration_test/usp_native_files_test.dart',
        f'--dart-define-from-file={args.defines.resolve()}'], cwd=root,
        stdout=log, stderr=subprocess.STDOUT)
    if build.returncode:
        raise SystemExit(build.returncode)
    result = subprocess.run(command, cwd=root / 'android', env=os.environ.copy(),
                            stdout=log, stderr=subprocess.STDOUT)
print(f'Native file validation exit: {result.returncode}; log: {args.log}')
raise SystemExit(result.returncode)
