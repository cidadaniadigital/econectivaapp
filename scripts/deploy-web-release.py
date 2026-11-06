#!/usr/bin/env python3
"""Publish an already-built web release, retaining the previous document root.

Does not build, access databases, edit Apache or remove releases. Run only after
API compatibility, backup and local validation have been checked.
"""
import argparse
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import re
import shlex
import subprocess
import tarfile
import tempfile

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--build', type=Path, required=True)
parser.add_argument('--revision', required=True)
parser.add_argument('--prepare-only', action='store_true', help='Version entrypoints without publishing')
parser.add_argument('--host', default='ubuntu@54.94.142.29')
args = parser.parse_args()
if not re.fullmatch(r'[0-9a-f]{7,40}', args.revision):
    parser.error('Use a verified commit revision.')
root = args.build.resolve()
for name in ['index.html', 'main.dart.js', 'flutter_bootstrap.js']:
    if not (root / name).is_file():
        parser.error('Missing compiled asset: ' + name)
# Preserve the complete icon fonts already repaired in production. Dynamic icon
# selections in the shared widgets package are not all visible to tree shaking.
for relative, minimum in {
    'assets/fonts/MaterialIcons-Regular.otf': 1_000_000,
    'assets/packages/cupertino_icons/assets/CupertinoIcons.ttf': 200_000,
}.items():
    font = root / relative
    if not font.is_file() or font.stat().st_size < minimum:
        parser.error('Build with --no-tree-shake-icons to preserve the complete icon fonts: ' + relative)
for path in root.rglob('*'):
    if path.is_symlink() or path.name == '.env' or 'service_account' in path.name:
        parser.error('Refusing symlink or protected configuration in the build.')
# HTTP caches may retain the previous bootstrap/main even after index reloads.
# Give both entrypoints the same release identity; Flutter assets and push scope
# remain unchanged. A custom query also bypasses legacy Flutter workers that
# strip their own ?v= parameter. Repeat deployments of the same build are idempotent.
index = root / 'index.html'
bootstrap = root / 'flutter_bootstrap.js'
html, index_count = re.subn(r'flutter_bootstrap\.js(?:\?(?:v|atopos_release)=[0-9a-f]+)?',
                            'flutter_bootstrap.js?atopos_release=' + args.revision, index.read_text())
loader, main_count = re.subn(r'"mainJsPath":"main\.dart\.js(?:\?(?:v|atopos_release)=[0-9a-f]+)?"',
                            '"mainJsPath":"main.dart.js?atopos_release=' + args.revision + '"', bootstrap.read_text())
if index_count != 1 or main_count != 1:
    parser.error('Unexpected Flutter entrypoint format; release was not published.')
# Older/default Flutter builds register the cleanup worker on every page load.
# Disable that registration too, so publishing an existing build is safe.
loader = re.sub(r'_flutter\.loader\.load\(\{\s*serviceWorkerSettings:\s*\{\s*serviceWorkerVersion:\s*"[^"]*"\s*\}\s*\}\);',
                '_flutter.loader.load();', loader)
index.write_text(html)
bootstrap.write_text(loader)
# Replace legacy Flutter workers with a cleanup worker. Keep Firebase messaging
# in its separate scope. A previous worker update can now activate immediately.
(root / 'flutter_service_worker.js').write_text("""self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', event => event.waitUntil((async () => {
  for (const key of ['flutter-app-cache', 'flutter-temp-cache', 'flutter-app-manifest']) {
    await caches.delete(key);
  }
  await self.clients.claim();
  await self.registration.unregister();
})()));
""")
(root / 'deployment.json').write_text(json.dumps({'commit': args.revision}))
if args.prepare_only:
    print(json.dumps({'prepared': str(root), 'revision': args.revision}))
    raise SystemExit(0)
release = 'atopos-' + datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ') + '-' + args.revision[:7]
with tempfile.TemporaryDirectory(prefix='atopos-web-release-') as temp:
    archive = Path(temp) / (release + '.tgz')
    with tarfile.open(archive, 'w:gz') as output:
        for path in sorted(root.iterdir()):
            output.add(path, arcname=path.name)
    digest = hashlib.sha256(archive.read_bytes()).hexdigest()
    remote_archive = '/tmp/' + archive.name
    subprocess.run(['scp', '-q', str(archive), args.host + ':' + remote_archive], check=True)
    remote = r'''
import hashlib,json,os,subprocess,sys
from pathlib import Path
p=json.load(sys.stdin)
archive=Path(p['archive'])
assert hashlib.sha256(archive.read_bytes()).hexdigest()==p['sha256']
base=Path('/var/www/atopos-releases');target=base/p['release'];web=Path('/var/www/usp_app_atopos')
assert not target.exists() and (web.is_dir() or web.is_symlink())
subprocess.run(['sudo','install','-d','-o','ubuntu','-g','ubuntu','-m','755',str(base)],check=True)
target.mkdir(mode=0o755)
subprocess.run(['tar','--no-same-owner','-xzf',str(archive),'-C',str(target)],check=True)
assert (target/'index.html').is_file() and (target/'main.dart.js').is_file()
previous=str(web.resolve()) if web.is_symlink() else str(base/('previous-'+p['release']))
for path in target.rglob('*'):
 path.chmod(0o755 if path.is_dir() else 0o644)
link=Path('/var/www/usp_app_atopos.next-'+p['release'])
subprocess.run(['sudo','ln','-s',str(target),str(link)],check=True)
moved=False
try:
 if not web.is_symlink():
  subprocess.run(['sudo','mv',str(web),previous],check=True)
  moved=True
 subprocess.run(['sudo','mv','-Tf',str(link),str(web)],check=True)
except BaseException:
 if moved and not web.exists():
  subprocess.run(['sudo','mv',previous,str(web)],check=True)
 raise
manifest={'revision':p['revision'],'archive_sha256':p['sha256'],'previous_root':previous,'release':str(target)}
private=Path('/home/ubuntu/backups/atopos-web-releases')
private.mkdir(parents=True,exist_ok=True,mode=0o700)
record=private/(p['release']+'.json')
record.write_text(json.dumps(manifest,indent=2));record.chmod(0o600)
(target/'atopos-release.json').write_text(json.dumps({'revision':p['revision'],'archive_sha256':p['sha256']},indent=2))
for url in ['https://plataforma.atopos.spotec.app/']:
 result=subprocess.run(['curl','-fSs','-o','/dev/null',url],capture_output=True)
 if result.returncode:
  subprocess.run(['sudo','ln','-sfn',previous,str(web)],check=True)
  raise SystemExit('Frontend check failed; previous document root restored, both Atopos releases retained')
archive.unlink()
print(json.dumps(manifest))
'''
    payload = {'archive': remote_archive, 'sha256': digest, 'release': release, 'revision': args.revision}
    subprocess.run(['ssh', '-o', 'BatchMode=yes', args.host, 'python3 -c ' + shlex.quote(remote)],
                   input=json.dumps(payload), text=True, check=True)
