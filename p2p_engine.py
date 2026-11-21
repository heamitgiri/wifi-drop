#!/usr/bin/env python3
"""
WiFi Drop — Symmetric Peer-to-Peer LAN Engine (v1.0)
No central hub required. Every instance discovers every other instance
via local UDP broadcast and transfers files directly peer-to-peer.
"""

import argparse
import hashlib
import json
import os
from pathlib import Path
import platform
import secrets
import socket
import sys
import threading
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import parse_qs, urlparse

# Constants & Defaults
DEFAULT_HTTP_PORT = 8765
DISCOVERY_PORT = 8766
MULTICAST_GROUP = '239.255.255.250'
BROADCAST_ADDR = '255.255.255.255'
PEER_TTL = 14
CHUNK_SIZE = 1024 * 1024  # 1 MB

BASE_DIR = Path(__file__).resolve().parent
WEB_DIR = BASE_DIR / 'p2p_app'

def get_default_save_dir():
    if platform.system() == 'Windows':
        user_profile = os.environ.get('USERPROFILE', '')
        if user_profile:
            return Path(user_profile) / 'Downloads' / 'WiFi Drop'
    home = Path.home()
    return home / 'Downloads' / 'WiFi Drop'

class P2PNode:
    def __init__(self, name=None, device_type=None, http_port=DEFAULT_HTTP_PORT, save_dir=None):
        self.node_id = secrets.token_hex(8)
        self.http_port = http_port
        self.device_type = device_type or ('phone' if any(k in platform.platform().lower() for k in ('android', 'ios', 'arm')) else 'laptop')
        self.name = name or (socket.gethostname() or ('My Laptop' if self.device_type == 'laptop' else 'My Phone'))
        self.save_dir = Path(save_dir) if save_dir else get_default_save_dir()
        self.save_dir.mkdir(parents=True, exist_ok=True)
        self.ask_before_receiving = True

        self.lan_ip = self._detect_lan_ip()
        self.lock = threading.RLock()
        self.peers = {}        # peer_id -> {id, name, type, ip, port, last_seen, color_index}
        self.transfers = {}    # transfer_id -> metadata
        self.running = True

    def _detect_lan_ip(self):
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        try:
            s.connect(('192.0.2.1', 80))
            return s.getsockname()[0]
        except OSError:
            return '127.0.0.1'
        finally:
            s.close()

    def sanitize_filename(self, filename):
        clean = Path(filename).name
        clean = ''.join(c for c in clean if c.isprintable() and c not in '/\\<>:"|?*\x00').strip().strip('.')
        return (clean or 'unnamed_file')[:120]

    def get_safe_destination(self, filename):
        clean = self.sanitize_filename(filename)
        dest = self.save_dir / clean
        if not dest.exists():
            return dest
        stem = dest.stem
        suffix = dest.suffix
        counter = 1
        while True:
            candidate = self.save_dir / f"{stem} ({counter}){suffix}"
            if not candidate.exists():
                return candidate
            counter += 1

    def prune_peers(self):
        now = time.time()
        with self.lock:
            stale = [pid for pid, p in self.peers.items() if now - p['last_seen'] > PEER_TTL]
            for pid in stale:
                del self.peers[pid]

    def register_peer(self, peer_id, name, ptype, ip, port):
        if peer_id == self.node_id:
            return
        now = time.time()
        with self.lock:
            if peer_id not in self.peers:
                color_index = abs(hash(peer_id)) % 8
                self.peers[peer_id] = {
                    'id': peer_id,
                    'name': name,
                    'type': ptype,
                    'ip': ip,
                    'port': port,
                    'last_seen': now,
                    'color_index': color_index
                }
            else:
                self.peers[peer_id].update({
                    'name': name,
                    'type': ptype,
                    'ip': ip,
                    'port': port,
                    'last_seen': now
                })

class DiscoveryManager:
    def __init__(self, node: P2PNode):
        self.node = node
        self.broadcast_sock = None
        self.listen_sock = None
        self.thread = None

    def start(self):
        # UDP listener socket
        self.listen_sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        self.listen_sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        if hasattr(socket, 'SO_REUSEPORT') and platform.system() != 'Windows':
            try: self.listen_sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEPORT, 1)
            except OSError: pass

        try:
            self.listen_sock.bind(('', DISCOVERY_PORT))
        except OSError:
            # Fallback to listening on broadcast port or ephemeral
            pass

        # Join multicast group
        try:
            mreq = socket.inet_aton(MULTICAST_GROUP) + socket.inet_aton('0.0.0.0')
            self.listen_sock.setsockopt(socket.IPPROTO_IP, socket.IP_ADD_MEMBERSHIP, mreq)
        except OSError:
            pass

        # UDP broadcast sender socket
        self.broadcast_sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        self.broadcast_sock.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)

        self.thread = threading.Thread(target=self._run_loop, daemon=True)
        self.thread.start()

    def _run_loop(self):
        last_beacon = 0
        while self.node.running:
            now = time.time()
            if now - last_beacon >= 2.5:
                self._send_beacon()
                self.node.prune_peers()
                last_beacon = now

            # Non-blocking or short-timeout recv
            try:
                self.listen_sock.settimeout(0.5)
                data, addr = self.listen_sock.recvfrom(2048)
                self._handle_beacon(data, addr[0])
            except (socket.timeout, OSError):
                pass

    def _send_beacon(self):
        payload = json.dumps({
            'proto': 'wifidrop_v1',
            'id': self.node.node_id,
            'name': self.node.name,
            'type': self.node.device_type,
            'port': self.node.http_port
        }).encode('utf-8')

        try:
            self.broadcast_sock.sendto(payload, (BROADCAST_ADDR, DISCOVERY_PORT))
            self.broadcast_sock.sendto(payload, (MULTICAST_GROUP, DISCOVERY_PORT))
        except OSError:
            pass

    def _handle_beacon(self, data, remote_ip):
        try:
            msg = json.loads(data.decode('utf-8'))
            if msg.get('proto') == 'wifidrop_v1':
                self.node.register_peer(
                    peer_id=msg['id'],
                    name=msg.get('name', 'Peer'),
                    ptype=msg.get('type', 'laptop'),
                    ip=remote_ip,
                    port=msg.get('port', DEFAULT_HTTP_PORT)
                )
        except (json.JSONDecodeError, KeyError):
            pass

class HTTPHandler(BaseHTTPRequestHandler):
    server_version = 'WiFiDropP2P/1.0'

    def log_message(self, fmt, *args):
        if not self.path.startswith('/api/status'):
            super().log_message(fmt, *args)

    @property
    def node(self) -> P2PNode:
        return self.server.node

    def send_cors(self):
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type, X-Transfer-Id')

    def json_resp(self, data, status=200):
        body = json.dumps(data, ensure_ascii=False).encode('utf-8')
        self.send_response(status)
        self.send_header('Content-Type', 'application/json; charset=utf-8')
        self.send_header('Content-Length', str(len(body)))
        self.send_cors()
        self.end_headers()
        self.wfile.write(body)

    def err_resp(self, msg, status=400):
        self.json_resp({'error': msg}, status)

    def do_OPTIONS(self):
        self.send_response(200)
        self.send_cors()
        self.end_headers()

    def do_GET(self):
        u = urlparse(self.path)
        if u.path in ('/', '/index.html'):
            html_path = WEB_DIR / 'index.html'
            if html_path.exists():
                content = html_path.read_bytes()
                self.send_response(200)
                self.send_header('Content-Type', 'text/html; charset=utf-8')
                self.send_header('Content-Length', str(len(content)))
                self.end_headers()
                self.wfile.write(content)
                return
            return self.err_resp('Web UI not found', 404)

        if u.path == '/api/status':
            with self.node.lock:
                peer_list = list(self.node.peers.values())
                tx_list = list(self.node.transfers.values())
            self.json_resp({
                'me': {
                    'id': self.node.node_id,
                    'name': self.node.name,
                    'type': self.node.device_type,
                    'ip': self.node.lan_ip,
                    'port': self.node.http_port,
                    'save_folder': str(self.node.save_dir),
                    'ask_before_receiving': self.node.ask_before_receiving
                },
                'peers': peer_list,
                'transfers': tx_list
            })
            return

        self.err_resp('Not found', 404)

    def do_POST(self):
        u = urlparse(self.path)

        # 1. P2P Endpoints
        if u.path == '/api/p2p/offer':
            length = int(self.headers.get('Content-Length', 0))
            data = json.loads(self.rfile.read(length).decode('utf-8'))
            tid = data['transfer_id']
            with self.node.lock:
                self.node.transfers[tid] = {
                    'id': tid,
                    'peer_id': data['sender_id'],
                    'peer_name': data['sender_name'],
                    'file_name': data['file_name'],
                    'file_size': data['file_size'],
                    'sha256': data.get('sha256', ''),
                    'is_incoming': True,
                    'status': 'pending',
                    'bytes_transferred': 0,
                    'created': time.time()
                }
                auto_accept = not self.node.ask_before_receiving
                if auto_accept:
                    self.node.transfers[tid]['status'] = 'accepted'

            self.json_resp({'accepted': auto_accept, 'transfer_id': tid})
            return

        if u.path == '/api/p2p/stream':
            tid = self.headers.get('X-Transfer-Id', '')
            with self.node.lock:
                tx = self.node.transfers.get(tid)
            if not tx or tx['status'] not in ('accepted', 'pending'):
                return self.err_resp('Transfer not accepted or expired', 403)

            tx['status'] = 'transferring'
            temp_file = self.node.save_dir / f".wifidrop_temp_{tid}.part"
            hasher = hashlib.sha256()
            received = 0
            size = tx['file_size']

            try:
                with temp_file.open('wb') as f:
                    while received < size:
                        to_read = min(CHUNK_SIZE, size - received)
                        chunk = self.rfile.read(to_read)
                        if not chunk:
                            raise ConnectionError('Stream ended prematurely')
                        f.write(chunk)
                        hasher.update(chunk)
                        received += len(chunk)
                        tx['bytes_transferred'] = received

                # Checksum verify
                computed_hash = hasher.hexdigest()
                expected_hash = tx.get('sha256', '')
                if expected_hash and computed_hash.lower() != expected_hash.lower():
                    temp_file.unlink(missing_ok=True)
                    tx['status'] = 'failed'
                    tx['error'] = 'SHA-256 verification failed'
                    return self.err_resp('Checksum mismatch', 422)

                # Move to final non-colliding path
                final_dest = self.node.get_safe_destination(tx['file_name'])
                temp_file.rename(final_dest)
                tx['status'] = 'completed'
                tx['file_path'] = str(final_dest)
                self.json_resp({'status': 'completed', 'path': str(final_dest)})
            except Exception as e:
                temp_file.unlink(missing_ok=True)
                tx['status'] = 'failed'
                tx['error'] = str(e)
                self.err_resp(str(e), 500)
            return

        # 2. Local Control Endpoints
        if u.path == '/api/control/decision':
            length = int(self.headers.get('Content-Length', 0))
            data = json.loads(self.rfile.read(length).decode('utf-8'))
            tid = data['transfer_id']
            accept = bool(data.get('accept', False))
            with self.node.lock:
                tx = self.node.transfers.get(tid)
                if tx and tx['status'] == 'pending':
                    tx['status'] = 'accepted' if accept else 'rejected'
            self.json_resp({'status': tx['status'] if tx else 'not_found'})
            return

        if u.path == '/api/control/settings':
            length = int(self.headers.get('Content-Length', 0))
            data = json.loads(self.rfile.read(length).decode('utf-8'))
            if 'name' in data and data['name'].strip():
                self.node.name = data['name'].strip()[:40]
            if 'save_folder' in data and data['save_folder'].strip():
                new_path = Path(data['save_folder'].strip())
                new_path.mkdir(parents=True, exist_ok=True)
                self.node.save_dir = new_path
            if 'ask_before_receiving' in data:
                self.node.ask_before_receiving = bool(data['ask_before_receiving'])
            self.json_resp({'status': 'updated'})
            return

        self.err_resp('Not found', 404)

def run_server(node: P2PNode):
    class CustomServer(ThreadingHTTPServer):
        def __init__(self, addr, handler):
            super().__init__(addr, handler)
            self.node = node

    while True:
        try:
            httpd = CustomServer(('0.0.0.0', node.http_port), HTTPHandler)
            break
        except OSError:
            node.http_port += 1

    print(f"\n[WiFi Drop P2P Node Online]")
    print(f"Device Name: {node.name} ({node.device_type})")
    print(f"Save Folder: {node.save_dir}")
    print(f"Radar Screen: http://127.0.0.1:{node.http_port}")
    print(f"LAN Address:  http://{node.lan_ip}:{node.http_port}")
    print(f"UDP Discovery: Port {DISCOVERY_PORT} (Zero-Hub Symmetric Mesh)\n", flush=True)

    httpd.serve_forever()

def main():
    parser = argparse.ArgumentParser(description='WiFi Drop Symmetric P2P Node')
    parser.add_argument('--name', help='Friendly device name')
    parser.add_argument('--type', choices=['laptop', 'phone'], default=None)
    parser.add_argument('--port', type=int, default=DEFAULT_HTTP_PORT)
    parser.add_argument('--save-dir', help='Custom received files save directory')
    args = parser.parse_args()

    node = P2PNode(name=args.name, device_type=args.type, http_port=args.port, save_dir=args.save_dir)
    discovery = DiscoveryManager(node)
    discovery.start()

    run_server(node)

if __name__ == '__main__':
    main()
