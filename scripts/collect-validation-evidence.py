#!/usr/bin/env python3
"""Receive sanitized PNG/JSON validation evidence over loopback only."""
import argparse
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import json
from pathlib import Path
import re

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--port', type=int, default=8774)
parser.add_argument('--directory', type=Path, default=Path('docs/validation/usp-plan'))
args = parser.parse_args()
root = args.directory.resolve()
root.mkdir(parents=True, exist_ok=True)

class Handler(BaseHTTPRequestHandler):
    def log_message(self, *_):
        pass

    def do_GET(self):
        if self.path != '/__health':
            self.send_error(404)
            return
        data = b'{"status":"ready","purpose":"usp-validation-evidence"}'
        self.send_response(200)
        self.send_header('Content-Type', 'application/json')
        self.send_header('Content-Length', str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def do_POST(self):
        match = re.fullmatch(r'/(android|linux|web)/([a-z0-9][a-z0-9-]*\.(png|json))', self.path)
        try:
            size = int(self.headers.get('Content-Length', '0'))
        except ValueError:
            size = 0
        if not match or not 0 < size <= 8 * 1024 * 1024:
            self.send_error(400)
            return
        data = self.rfile.read(size)
        if len(data) != size or (match[3] == 'png' and not data.startswith(b'\x89PNG\r\n\x1a\n')):
            self.send_error(400)
            return
        if match[3] == 'json':
            try:
                json.loads(data)
            except (ValueError, UnicodeDecodeError):
                self.send_error(400)
                return
        destination = root / match[1] / match[2]
        if not destination.resolve().is_relative_to(root):
            self.send_error(400)
            return
        destination.parent.mkdir(parents=True, exist_ok=True)
        temporary = destination.with_suffix(destination.suffix + '.pending')
        temporary.write_bytes(data)
        temporary.replace(destination)
        self.send_response(201)
        self.send_header('Content-Length', '0')
        self.end_headers()

ThreadingHTTPServer(('127.0.0.1', args.port), Handler).serve_forever()
