#!/usr/bin/env python3
"""Run the actual Android Back/orientation/keyboard regression on the local preview."""
import argparse
import base64
import json
import os
from pathlib import Path
import subprocess
from urllib.parse import urlparse
parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('--defines',type=Path,required=True)
parser.add_argument('--log',type=Path,required=True)
parser.add_argument('--serial',default='emulator-5554')
args=parser.parse_args()
if args.defines.stat().st_mode & 0o077:parser.error('The defines file must be private (chmod 600).')
values=json.loads(args.defines.read_text())
if urlparse(values.get('API_BASE_URL','')).hostname!='127.0.0.1':parser.error('This test requires the isolated loopback API.')
root=Path(__file__).resolve().parents[1]
encoded=','.join(base64.b64encode(f'{key}={value}'.encode()).decode() for key,value in values.items())
args.log.touch(mode=0o600);args.log.chmod(0o600)
adb=['adb','-s',args.serial]
keyboard=subprocess.check_output(adb+['shell','settings','get','secure','show_ime_with_hard_keyboard'],text=True,timeout=10).strip()
subprocess.run(adb+['shell','settings','put','secure','show_ime_with_hard_keyboard','1'],check=True,timeout=10)
try:
 with args.log.open('w') as log:
  build=subprocess.run(['flutter','build','apk','--debug','--target',
    'integration_test/usp_native_controls_test.dart',
    f'--dart-define-from-file={args.defines.resolve()}'],cwd=root,
    stdout=log,stderr=subprocess.STDOUT)
  if build.returncode:raise SystemExit(build.returncode)
  result=subprocess.run(['./gradlew',':app:connectedDebugAndroidTest',
  '-Pandroid.testInstrumentationRunnerArguments.class=com.br.spotecnologia.uniuspapp.NativeControlsTest',
  f'-Ptarget={root}/integration_test/usp_native_controls_test.dart',f'-Pdart-defines={encoded}'],
  cwd=root/'android',env=os.environ.copy(),stdout=log,stderr=subprocess.STDOUT)
finally:
 if keyboard=='null':subprocess.run(adb+['shell','settings','delete','secure','show_ime_with_hard_keyboard'],check=True,stdout=subprocess.DEVNULL,timeout=10)
 else:subprocess.run(adb+['shell','settings','put','secure','show_ime_with_hard_keyboard',keyboard],check=True,timeout=10)
summary=args.log.with_suffix('.result.json')
summary.touch(mode=0o600);summary.chmod(0o600)
summary.write_text(json.dumps({'runner_exit':result.returncode,'keyboard_setting_restored':True}))
print(f'Native controls validation exit: {result.returncode}; log: {args.log}',flush=True)
raise SystemExit(result.returncode)
