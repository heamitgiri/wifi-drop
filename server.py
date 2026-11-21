#!/usr/bin/env python3
"""WiFi Drop LAN MVP: no Python dependencies. Run on a trusted private Wi-Fi."""
import argparse
import base64
import hmac
import json
import mimetypes
import os
from pathlib import Path
import secrets
import socket
import threading
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import parse_qs, urlparse

BASE = Path(__file__).resolve().parent
WEB = BASE / 'app'
SPOOL = BASE / 'received_cache'
CLIENT_TTL = 16
FILE_TTL = 24 * 3600
LOCK = threading.RLock()
clients = {}       # client_id -> {name, type, seen, token}
transfers = {}     # transfer_id -> metadata
access_code = ''
max_file_bytes = 10 * 1024**3

def lan_ip():
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.connect(('192.0.2.1', 80))
        return s.getsockname()[0]
    except OSError:
        return '127.0.0.1'
    finally:
        s.close()

def clean_name(value, maxlen=75):
    name = ''.join(ch for ch in str(value) if ch.isprintable() and ch not in '/\\<>:"|?*\x00').strip().strip('.')
    return (name or 'Unnamed')[:maxlen]

def cleanup():
    now = time.time()
    with LOCK:
        for uid, p in list(clients.items()):
            if now - p['seen'] > CLIENT_TTL:
                del clients[uid]
        for tid, t in list(transfers.items()):
            if now - t['created'] > FILE_TTL:
                try: (SPOOL / tid).unlink(missing_ok=True)
                except OSError: pass
                del transfers[tid]

class Handler(BaseHTTPRequestHandler):
    server_version = 'WiFiDropMVP/0.1'
    def log_message(self, fmt, *args):
        if not self.path.startswith('/api/peers'):
            super().log_message(fmt, *args)
    def headers_safe(self, code, content_type, n=None):
        self.send_response(code)
        self.send_header('Content-Type', content_type)
        self.send_header('Cache-Control', 'no-store')
        self.send_header('X-Content-Type-Options', 'nosniff')
        self.send_header('Referrer-Policy', 'no-referrer')
        self.send_header('X-Frame-Options', 'DENY')
        if n is not None: self.send_header('Content-Length', str(n))
    def json(self, obj, status=200):
        body = json.dumps(obj, ensure_ascii=False).encode()
        self.headers_safe(status, 'application/json; charset=utf-8', len(body))
        self.end_headers()
        self.wfile.write(body)
    def err(self, error, status=400):
        self.json({'error':error},status)
    def read_json(self):
        n = int(self.headers.get('Content-Length','0'))
        if n > 32768 or n <= 0: raise ValueError('Invalid request size')
        return json.loads(self.rfile.read(n))
    def auth(self):
        uid = self.headers.get('X-Device-Id','')
        token = self.headers.get('X-Session-Token','')
        with LOCK:
            c = clients.get(uid)
            if not c or not hmac.compare_digest(c['token'],token): return None
            c['seen'] = time.time()
        return uid
    def do_GET(self):
        u = urlparse(self.path)
        if u.path in ('/', '/index.html'):
            p = WEB/'index.html'
            b = p.read_bytes(); self.headers_safe(200,'text/html; charset=utf-8',len(b)); self.end_headers(); self.wfile.write(b); return
        if u.path == '/api/config':
            self.json({'server':'WiFi Drop LAN','needs_code':True,'version':'0.1.0'});return
        if u.path == '/api/peers':
            uid = self.auth()
            if not uid: return self.err('Sign in required',401)
            cleanup()
            with LOCK:
                peers = [{'id':k,'name':v['name'],'type':v['type']} for k,v in clients.items() if k != uid]
                mine = {'id':uid,'name':clients[uid]['name']}
                mine_transfers = [{k:t[k] for k in ('id','name','size','source','target','status','created','bytes')} for t in transfers.values() if t['source']==uid or t['target']==uid]
            self.json({'peers':peers,'me':mine,'transfers':mine_transfers});return
        if u.path == '/api/file':
            qs = parse_qs(u.query)
            ticket = qs.get('ticket',[''])[0]
            tid = qs.get('id',[''])[0]
            with LOCK:
                t = transfers.get(tid)
                if not t or t['status'] not in ('accepted','completed') or not hmac.compare_digest(t.get('ticket',''),ticket):
                    return self.err('Invalid or expired download link',403)
                # Single-use capability, prevent repeated unsolicited downloads.
                t['ticket'] = ''
                path = SPOOL/tid
                filename = t['name']
            if not path.is_file(): return self.err('File missing',404)
            try:
                size = path.stat().st_size
                self.headers_safe(200,'application/octet-stream',size)
                escaped = ''.join(ch if ch.isalnum() or ch in '-_. ' else '_' for ch in filename)
                self.send_header('Content-Disposition', "attachment; filename*=UTF-8''"+__import__('urllib.parse',fromlist=['quote']).quote(escaped))
                self.end_headers()
                with path.open('rb') as f:
                    while data:=f.read(1024*1024): self.wfile.write(data)
                with LOCK: t['status']='completed'
            except (BrokenPipeError,ConnectionResetError):
                with LOCK: t['status']='accepted'
            return
        self.err('Not found',404)
    def do_POST(self):
        u=urlparse(self.path)
        if u.path=='/api/join':
            try:
                data=self.read_json()
                if not hmac.compare_digest(str(data.get('code','')),access_code): return self.err('Wrong Wi-Fi sharing code',403)
                uid=secrets.token_urlsafe(18); token=secrets.token_urlsafe(32)
                name=clean_name(data.get('name','My Device'),40)
                device_type=data.get('type','phone')
                if device_type not in ('phone','laptop'):device_type='phone'
                with LOCK: clients[uid]={'token':token,'name':name,'type':device_type,'seen':time.time()}
                self.json({'id':uid,'token':token,'name':name});return
            except (ValueError,TypeError,KeyError):return self.err('Invalid device details')
        uid=self.auth()
        if not uid: return self.err('Sign in required',401)
        if u.path=='/api/upload':
            q=parse_qs(u.query)
            target=q.get('target',[''])[0]
            name=clean_name(q.get('name',['file'])[0],120)
            try: size=int(self.headers.get('Content-Length','-1'))
            except ValueError: size=-1
            if size<0 or size>max_file_bytes:return self.err('Invalid file size / too large',413)
            with LOCK:
                if target not in clients or target==uid:return self.err('Receiving device offline',409)
            tid=secrets.token_urlsafe(17)
            path=SPOOL/tid
            received=0
            try:
                with path.open('xb') as f:
                    while received<size:
                        chunk=self.rfile.read(min(1024*1024,size-received))
                        if not chunk:raise ConnectionError('Upload interrupted')
                        f.write(chunk); received+=len(chunk)
            except (OSError,ConnectionError):
                path.unlink(missing_ok=True)
                return self.err('Upload interrupted or disk full',507)
            with LOCK:
                if target not in clients:
                    path.unlink(missing_ok=True)
                    return self.err('Recipient disconnected during upload',409)
                transfers[tid]={'id':tid,'name':name,'size':size,'bytes':size,'source':uid,'target':target,'status':'pending','created':time.time(),'ticket':''}
            self.json({'id':tid,'status':'pending'});return
        try: data=self.read_json()
        except (ValueError,TypeError):return self.err('Invalid request')
        if u.path=='/api/decision':
            tid=data.get('id',''); accept=data.get('accept',False)
            with LOCK:
                t=transfers.get(tid)
                if not t or t['target']!=uid or t['status']!='pending':return self.err('Request unavailable',404)
                t['status']='accepted' if accept else 'rejected'
                if accept:
                    t['ticket']=secrets.token_urlsafe(32)
                    ticket=t['ticket']
                else: ticket=''
            if not accept:(SPOOL/tid).unlink(missing_ok=True)
            self.json({'status':'accepted' if accept else 'rejected','ticket':ticket});return
        if u.path=='/api/cancel':
            tid=data.get('id','')
            with LOCK:
                t=transfers.get(tid)
                if not t or uid not in (t['source'],t['target']): return self.err('Transfer unavailable',404)
                if t['status']=='completed':return self.err('Already completed',409)
                t['status']='cancelled';t['ticket']=''
            (SPOOL/tid).unlink(missing_ok=True)
            self.json({'status':'cancelled'});return
        self.err('Not found',404)

def main():
    global access_code,max_file_bytes
    parser=argparse.ArgumentParser(description='WiFi Drop private-LAN prototype')
    parser.add_argument('--port',type=int,default=8765)
    parser.add_argument('--code',default=None,help='Six-digit sharing code (defaults random)')
    parser.add_argument('--max-gb',type=float,default=10)
    args=parser.parse_args()
    access_code=args.code or f'{secrets.randbelow(1000000):06d}'
    if len(access_code)!=6 or not access_code.isdigit():parser.error('--code must be six digits')
    max_file_bytes=int(args.max_gb*1024**3)
    SPOOL.mkdir(exist_ok=True)
    httpd=ThreadingHTTPServer(('0.0.0.0',args.port),Handler)
    ip=lan_ip()
    print('\n'+'='*55)
    print('WiFi Drop — functional LAN prototype')
    print(f'On this PC: http://127.0.0.1:{args.port}')
    print(f'On same Wi-Fi: http://{ip}:{args.port}')
    print(f'JOIN CODE: {access_code}')
    print('Keep this window running. Press Ctrl+C to stop.')
    print('WARNING: HTTP is unencrypted; use private/trusted Wi-Fi only.')
    print('='*55+'\n',flush=True)
    try:httpd.serve_forever(poll_interval=0.3)
    except KeyboardInterrupt:pass
    finally:httpd.server_close()
if __name__=='__main__':main()
