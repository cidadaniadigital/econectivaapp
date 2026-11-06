"""Run Flutter checks sequentially, with a fresh desktop process per suite.
Supply a protected --dart-define-from-file JSON containing API_BASE_URL,
E2E_EMAIL and E2E_PASSWORD. The API must be an isolated loopback preview.
"""
import argparse, json, subprocess, sys
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--defines',required=True);args=p.parse_args()
settings=json.loads(Path(args.defines).read_text())
from urllib.parse import urlparse
if urlparse(settings['API_BASE_URL']).hostname not in {'localhost','127.0.0.1'}:raise SystemExit('Only an isolated loopback API is permitted')
commands=[('analyze',['flutter','analyze','--no-fatal-infos']),('unit',['flutter','test','--reporter','expanded'])]
for name in ['api_integration_test','login_screenshot_test','compatibility_crud_test','compatibility_test']:
 commands.append((name,['xvfb-run','-a','flutter','test',f'integration_test/{name}.dart','-d','linux','--concurrency=1',f'--dart-define-from-file={Path(args.defines).resolve()}','--reporter','expanded']))
# Prepare just the legacy selector fixture in the named disposable database.
seed = "INSERT INTO sample_details (sample_string,created_at,updated_at) SELECT 'UU97 detalhe sintético',NOW(),NOW() WHERE NOT EXISTS (SELECT 1 FROM sample_details WHERE sample_string='UU97 detalhe sintético')"
subprocess.run(['docker','exec','rieonlife-validation-db','sh','-c',
    'MYSQL_PWD="$MARIADB_ROOT_PASSWORD" mariadb -uroot onlife_validation_preview -e "$1"',
    'usp97-fixture',seed],check=True,capture_output=True)
results=[]
out=Path('docs/validation');out.mkdir(parents=True,exist_ok=True)
for name,command in commands:
 print(f'Running {name}',flush=True)
 # Client logging is filtered by WebClient so credentials are not written.
 with (out/f'{name}.log').open('w') as log:code=subprocess.run(command,stdout=log,stderr=subprocess.STDOUT).returncode
 results.append({'suite':name,'exit_code':code})
 (out/'suites.json').write_text(json.dumps(results,indent=2)+'\n')
 print(f'{name}: {"PASS" if code==0 else "FAIL"}',flush=True)
print('Validation complete',flush=True)
sys.exit(int(any(r['exit_code'] for r in results)))
