#!/usr/bin/env python3
"""Prepare or remove only the named disposable catalog pagination fixtures."""
import argparse
import json
from pathlib import Path
import re
import subprocess
from urllib.request import Request, urlopen

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--cleanup', action='store_true')
args = parser.parse_args()
base = 'http://127.0.0.1:8082/api'
lot = 'usp-catalog-pagination-v1'
container = json.loads(subprocess.check_output(['docker', 'inspect', 'rieonlife-validation-db']))[0]
assert container['HostConfig']['PortBindings']['3306/tcp'][0] == {'HostIp':'127.0.0.1','HostPort':'33419'}
credentials = json.loads(Path('/tmp/onlife-integration-preview-credentials.json').read_text())
token = None

def api(method, path, data=None):
    headers = {'Content-Type': 'application/json'}
    if token:
        headers['Authorization'] = 'Bearer ' + token
    with urlopen(Request(base + path, json.dumps(data).encode() if data is not None else None,
                         headers, method=method), timeout=45) as response:
        raw = response.read()
        return json.loads(raw) if raw else None

login = api('POST', '/login', {'email':credentials['email'], 'password':credentials['password'], 'device_name':'usp-pagination-local'})
token = login.get('token') or login.get('plain_text_token')
assert token
rows = api('GET', '/living_clues?limit=200&offset=0')
owned = [row for row in rows if re.fullmatch(r'USP paginação [0-9]{2}', row['name']) and row.get('metadata', {}).get('lote') == lot]
if args.cleanup:
    for row in owned:
        api('DELETE', f"/living_clues/{row['id']}")
    print('Removed disposable pagination fixtures:', len(owned))
else:
    category = next(row for row in api('GET', '/categories') if row['name'] == 'Laboratório de integrações')
    api('PUT','/me/preferences', {'usage_mode':'inventor'})
    by_name = {row['name']:row for row in owned}
    for number in range(1, 26):
        name = f'USP paginação {number:02}'
        if name not in by_name:
            api('POST', '/living_clues', {'name':name, 'category_id':category['id'],
                'description':f'Fixture fictícia descartável para busca na descrição: amostra-pagina-{number:02}.',
                'metadata':{'dados_ficticios':True,'lote':lot}})
    print('Prepared pagination fixtures: 25; category:', category['id'])
