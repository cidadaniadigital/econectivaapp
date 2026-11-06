#!/usr/bin/env python3
"""Loopback web preview, optionally simulating a version-metadata outage."""
import argparse
import json
import socket
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import urlparse

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--directory', default='build/web')
parser.add_argument('--port', type=int, default=8775)
parser.add_argument('--version-fault-file', type=Path)
parser.add_argument('--client-metadata', type=Path,
                    help='Optional private file for the validation browser User-Agent only')
args = parser.parse_args()

class Handler(SimpleHTTPRequestHandler):
    def do_GET(self):
        if urlparse(self.path).path == '/version.json' and args.client_metadata:
            args.client_metadata.touch(mode=0o600)
            args.client_metadata.chmod(0o600)
            args.client_metadata.write_text(json.dumps({
                'user_agent': self.headers.get('User-Agent', '')
            }))
        if urlparse(self.path).path == '/version.json' and args.version_fault_file and args.version_fault_file.exists():
            self.close_connection = True
            self.connection.shutdown(socket.SHUT_RDWR)
            self.connection.close()
            return
        super().do_GET()

ThreadingHTTPServer(('127.0.0.1',args.port),partial(Handler,directory=args.directory)).serve_forever()
