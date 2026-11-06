"""Read-only contract probe against an explicitly selected test API."""
import json, os, urllib.request, urllib.error
from pathlib import Path
base=os.environ.get('USP_TEST_API','http://127.0.0.1:8082/api')
credentials=json.loads(Path(os.environ.get('USP_TEST_CREDENTIALS','/tmp/onlife-integration-preview-credentials.json')).read_text())
req=urllib.request.Request(base+'/login',data=json.dumps({k:credentials[k] for k in ('email','password')}).encode(),headers={'Content-Type':'application/json'})
auth=json.load(urllib.request.urlopen(req)); token=auth.get('token',auth.get('plain_text_token'))
if not token: raise SystemExit('Login returned no token')
results=[]
for route in ['categories','living_clues','connection_types','clue_connections','node_types','nodes','node_links','sample_models','users','chat_templates','ai/messages','files']:
 try:
  req=urllib.request.Request(base+'/'+route,headers={'Authorization':'Bearer '+token})
  with urllib.request.urlopen(req) as res: data=json.load(res); status=res.status
  results.append({'route':route,'status':status,'shape':type(data).__name__,'count':len(data) if isinstance(data,list) else None})
 except urllib.error.HTTPError as e: results.append({'route':route,'status':e.code})
Path('docs/validation/api-probe.json').write_text(json.dumps(results,indent=2)+'\n')
print(json.dumps(results,indent=2))
