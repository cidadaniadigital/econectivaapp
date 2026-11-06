#!/usr/bin/env python3
"""Loopback-only API forwarding with authenticated, test-only HTTP 503 faults.

Upstream is fixed to the isolated preview on 8082. Request bodies, tokens and
responses are never logged. The key file must be private; do not commit it.
"""
import argparse
import hmac
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import json
from pathlib import Path
import re
import threading
from urllib.error import HTTPError, URLError
from urllib.parse import urlsplit
from urllib.request import Request, build_opener, HTTPRedirectHandler, ProxyHandler

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--port', type=int, default=8084)
parser.add_argument('--key-file', type=Path, required=True)
args = parser.parse_args()
if args.key_file.stat().st_mode & 0o077:
    parser.error('The key file must have mode 600.')
key = args.key_file.read_text().strip()
if len(key) < 24:
    parser.error('Use a generated test key of at least 24 characters.')
state = {'fault': 'none', 'injected': {}}
lock = threading.Lock()
limit = 8 * 1024 * 1024
hop = {'host', 'connection', 'keep-alive', 'proxy-authenticate',
       'proxy-authorization', 'te', 'trailers', 'transfer-encoding', 'upgrade', 'content-length'}

class NoRedirect(HTTPRedirectHandler):
    def redirect_request(self, *_args, **_kwargs):
        return None

opener = build_opener(ProxyHandler({}), NoRedirect())

class Handler(BaseHTTPRequestHandler):
    def log_message(self, *_):
        pass

    def json_response(self, status, data):
        body = json.dumps(data).encode()
        self.send_response(status)
        self.send_header('Content-Type', 'application/json')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Content-Length', str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def handle_request(self):
        path = urlsplit(self.path).path
        if path == '/__fault/health':
            return self.json_response(200, {'purpose': 'usp-validation-api-faults'})
        try:
            size = int(self.headers.get('Content-Length', '0'))
        except ValueError:
            size = -1
        if not 0 <= size <= limit:
            return self.json_response(413, {'message': 'Test proxy payload limit exceeded.'})
        body = self.rfile.read(size) if size else None
        if path == '/__fault/control':
            if not hmac.compare_digest(self.headers.get('X-USP-Fault-Key', ''), key):
                return self.json_response(403, {'message': 'Test control denied.'})
            if self.command == 'POST':
                try:
                    fault = json.loads(body or b'{}')['fault']
                except (ValueError, KeyError, TypeError):
                    return self.json_response(400, {'message': 'Invalid fault mode.'})
                if fault not in {'none', 'catalog', 'layers', 'chat'}:
                    return self.json_response(400, {'message': 'Unknown fault mode.'})
                with lock:
                    state['fault'] = fault
            with lock:
                return self.json_response(200, dict(state))
        if not path.startswith('/api/'):
            return self.json_response(404, {'message': 'Unknown test route.'})
        with lock:
            fault = state['fault']
            inject = ((fault == 'catalog' and self.command == 'GET' and path == '/api/living_clues') or
                      (fault == 'layers' and self.command == 'GET' and path == '/api/environmental_layers') or
                      (fault == 'chat' and self.command == 'POST' and
                       (path in {'/api/ai/messages', '/api/chat'} or
                        re.fullmatch(r'/api/(living_clues|chat_templates)/[0-9]+/(chat/)?messages', path))))
            if inject:
                state['injected'][fault] = state['injected'].get(fault, 0) + 1
        if inject:
            return self.json_response(503, {'message': 'Indisponibilidade simulada para validação local.'})
        headers = {k: v for k, v in self.headers.items() if k.lower() not in hop}
        request = Request('http://127.0.0.1:8082'+self.path, body, headers, method=self.command)
        try:
            try:
                response = opener.open(request, timeout=90)
            except HTTPError as error:
                response = error
            with response:
                data = response.read(limit+1)
                if len(data) > limit:
                    return self.json_response(502, {'message': 'Test proxy response limit exceeded.'})
                self.send_response(response.getcode())
                for name, value in response.headers.items():
                    if name.lower() not in hop | {'server', 'date'}:
                        self.send_header(name, value)
                self.send_header('Content-Length', str(len(data)))
                self.end_headers()
                self.wfile.write(data)
        except (URLError, TimeoutError, OSError):
            self.json_response(502, {'message': 'Prévia local indisponível.'})

    do_GET = do_POST = do_PUT = do_DELETE = do_PATCH = do_OPTIONS = handle_request

ThreadingHTTPServer(('127.0.0.1', args.port), Handler).serve_forever()
