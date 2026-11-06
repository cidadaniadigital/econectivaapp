"""Receive PNG evidence from the isolated Android emulator via adb reverse."""
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path
import re, json
ROOT = Path('docs/validation/usp-plan').resolve()
class Handler(BaseHTTPRequestHandler):
    def do_POST(self):
        if not re.fullmatch(r'/(android|linux)/[a-z0-9-]+\.(?:png|json)', self.path):
            self.send_error(400); return
        length = int(self.headers.get('Content-Length', '0'))
        if not 8 <= length <= 8 * 1024 * 1024:
            self.send_error(413); return
        data = self.rfile.read(length)
        valid = data.startswith(b'\x89PNG\r\n\x1a\n') if self.path.endswith('.png') else False
        if self.path.endswith('.json'):
            try: valid = isinstance(json.loads(data), (dict, list))
            except (ValueError, UnicodeDecodeError): pass
        if not valid:
            self.send_error(415); return
        target = ROOT / self.path.lstrip('/')
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(data)
        self.send_response(201); self.end_headers()
    def log_message(self, *_): pass
HTTPServer(('127.0.0.1', 8774), Handler).serve_forever()
