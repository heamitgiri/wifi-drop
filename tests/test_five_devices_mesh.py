#!/usr/bin/env python3
"""
Automated 5-Device Acceptance Test Suite for WiFi Drop
Simulates the exact physical scenario from Section 1 & Section 9 of the Build Spec:
- Laptop 1 (Windows 11)
- Laptop 2 (Windows 11)
- Laptop 3 (Windows 11)
- Phone 1 (Android)
- Phone 2 (Android)
"""

import hashlib
import json
from pathlib import Path
import tempfile
import threading
import time
import unittest
import urllib.request
import urllib.error

import sys
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from p2p_engine import P2PNode, HTTPHandler

class FiveDevicesAcceptanceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.tmp_root = tempfile.TemporaryDirectory()
        cls.root_path = Path(cls.tmp_root.name)

        # Configure 5 devices with isolated save folders
        cls.configs = [
            {'name': 'Laptop 1', 'type': 'laptop', 'port': 9001},
            {'name': 'Laptop 2', 'type': 'laptop', 'port': 9002},
            {'name': 'Laptop 3', 'type': 'laptop', 'port': 9003},
            {'name': 'Phone 1', 'type': 'phone', 'port': 9004},
            {'name': 'Phone 2', 'type': 'phone', 'port': 9005},
        ]

        from http.server import ThreadingHTTPServer

        cls.nodes = []
        cls.servers = []
        cls.threads = []

        for cfg in cls.configs:
            save_dir = cls.root_path / cfg['name'].replace(' ', '_')
            save_dir.mkdir(parents=True, exist_ok=True)
            node = P2PNode(name=cfg['name'], device_type=cfg['type'], http_port=cfg['port'], save_dir=save_dir)
            node.ask_before_receiving = False  # Enabled for auto-acceptance in automated matrix

            class CustomServer(ThreadingHTTPServer):
                pass
            server = CustomServer(('127.0.0.1', cfg['port']), HTTPHandler)
            server.node = node

            thread = threading.Thread(target=server.serve_forever, daemon=True)
            thread.start()

            cls.nodes.append(node)
            cls.servers.append(server)
            cls.threads.append(thread)

        # Cross-register all 5 nodes as peers
        for i, n1 in enumerate(cls.nodes):
            for j, n2 in enumerate(cls.nodes):
                if i != j:
                    n1.register_peer(n2.node_id, n2.name, n2.device_type, '127.0.0.1', n2.http_port)

    @classmethod
    def tearDownClass(cls):
        for s in cls.servers:
            s.shutdown()
            s.server_close()
        cls.tmp_root.cleanup()

    def test_01_all_five_devices_see_four_peers(self):
        """Every device sees the OTHER four devices automatically; self is never counted."""
        for i, cfg in enumerate(self.configs):
            req = urllib.request.Request(f"http://127.0.0.1:{cfg['port']}/api/status")
            with urllib.request.urlopen(req) as resp:
                data = json.loads(resp.read().decode('utf-8'))
                me = data['me']
                peers = data['peers']

                self.assertEqual(me['name'], cfg['name'])
                self.assertEqual(me['type'], cfg['type'])
                self.assertEqual(len(peers), 4, f"{cfg['name']} should see exactly 4 peers")

                # Verify self node is never counted among peers
                peer_ids = [p['id'] for p in peers]
                self.assertNotIn(me['id'], peer_ids, f"{cfg['name']} must not include itself on radar")

                # Verify all peer names match the other 4 devices
                peer_names = set(p['name'] for p in peers)
                expected_names = set(c['name'] for c in self.configs if c['name'] != cfg['name'])
                self.assertEqual(peer_names, expected_names)

    def test_02_transfer_phone1_to_laptop3(self):
        """Phone 1 sends 250 KB file to Laptop 3 with SHA-256 verification."""
        phone1 = self.nodes[3]  # Phone 1
        laptop3 = self.nodes[2] # Laptop 3

        content = b'A' * (250 * 1024)  # 250 KB payload
        file_hash = hashlib.sha256(content).hexdigest()
        tid = 'tx-phone1-lap3'

        # Offer
        offer_payload = {
            'transfer_id': tid,
            'sender_id': phone1.node_id,
            'sender_name': phone1.name,
            'file_name': 'project_specs.pdf',
            'file_size': len(content),
            'sha256': file_hash
        }
        req = urllib.request.Request(
            f"http://127.0.0.1:{laptop3.http_port}/api/p2p/offer",
            data=json.dumps(offer_payload).encode('utf-8'),
            headers={'Content-Type': 'application/json'}
        )
        with urllib.request.urlopen(req) as resp:
            data = json.loads(resp.read().decode('utf-8'))
            self.assertTrue(data['accepted'])

        # Stream
        stream_req = urllib.request.Request(
            f"http://127.0.0.1:{laptop3.http_port}/api/p2p/stream",
            data=content,
            headers={
                'X-Transfer-Id': tid,
                'Content-Length': str(len(content))
            }
        )
        with urllib.request.urlopen(stream_req) as resp:
            data = json.loads(resp.read().decode('utf-8'))
            self.assertEqual(data['status'], 'completed')

        # Check file in Laptop 3's destination
        dest = laptop3.save_dir / 'project_specs.pdf'
        self.assertTrue(dest.exists())
        self.assertEqual(dest.read_bytes(), content)

    def test_03_transfer_laptop2_to_phone2(self):
        """Laptop 2 sends 500 KB video to Phone 2."""
        laptop2 = self.nodes[1]
        phone2 = self.nodes[4]

        content = b'V' * (500 * 1024)
        file_hash = hashlib.sha256(content).hexdigest()
        tid = 'tx-lap2-phone2'

        offer = {
            'transfer_id': tid,
            'sender_id': laptop2.node_id,
            'sender_name': laptop2.name,
            'file_name': 'vacation_clip.mp4',
            'file_size': len(content),
            'sha256': file_hash
        }
        req = urllib.request.Request(
            f"http://127.0.0.1:{phone2.http_port}/api/p2p/offer",
            data=json.dumps(offer).encode('utf-8'),
            headers={'Content-Type': 'application/json'}
        )
        with urllib.request.urlopen(req) as resp:
            self.assertTrue(json.loads(resp.read().decode('utf-8'))['accepted'])

        stream_req = urllib.request.Request(
            f"http://127.0.0.1:{phone2.http_port}/api/p2p/stream",
            data=content,
            headers={'X-Transfer-Id': tid, 'Content-Length': str(len(content))}
        )
        with urllib.request.urlopen(stream_req) as resp:
            self.assertEqual(json.loads(resp.read().decode('utf-8'))['status'], 'completed')

        saved = phone2.save_dir / 'vacation_clip.mp4'
        self.assertTrue(saved.exists())
        self.assertEqual(saved.read_bytes(), content)

    def test_04_receiver_rejection_cleans_temporary_data(self):
        """Receiver declining an offer prevents saving and cleans any staged temp file."""
        laptop1 = self.nodes[0]
        phone1 = self.nodes[3]

        tid = 'tx-rejected-123'
        phone1.ask_before_receiving = True  # Require consent

        # Offer
        offer = {
            'transfer_id': tid,
            'sender_id': laptop1.node_id,
            'sender_name': laptop1.name,
            'file_name': 'unsolicited_data.exe',
            'file_size': 1024,
            'sha256': hashlib.sha256(b'test').hexdigest()
        }
        req = urllib.request.Request(
            f"http://127.0.0.1:{phone1.http_port}/api/p2p/offer",
            data=json.dumps(offer).encode('utf-8'),
            headers={'Content-Type': 'application/json'}
        )
        with urllib.request.urlopen(req) as resp:
            data = json.loads(resp.read().decode('utf-8'))
            self.assertFalse(data['accepted'])

        # Receiver explicitly declines
        dec_req = urllib.request.Request(
            f"http://127.0.0.1:{phone1.http_port}/api/control/decision",
            data=json.dumps({'transfer_id': tid, 'accept': False}).encode('utf-8'),
            headers={'Content-Type': 'application/json'}
        )
        with urllib.request.urlopen(dec_req) as resp:
            self.assertEqual(json.loads(resp.read().decode('utf-8'))['status'], 'rejected')

        # Stream attempt should be rejected with 403
        stream_req = urllib.request.Request(
            f"http://127.0.0.1:{phone1.http_port}/api/p2p/stream",
            data=b'bytes',
            headers={'X-Transfer-Id': tid, 'Content-Length': '5'}
        )
        with self.assertRaises(urllib.error.HTTPError) as cm:
            urllib.request.urlopen(stream_req)
        self.assertEqual(cm.exception.code, 403)

        # Confirm no file exists
        self.assertFalse((phone1.save_dir / 'unsolicited_data.exe').exists())
        self.assertFalse((phone1.save_dir / f".wifidrop_temp_{tid}.part").exists())
        phone1.ask_before_receiving = False

    def test_05_safe_duplicate_collision_naming(self):
        """Duplicate filename lands as 'name (1).ext' without overwriting existing file."""
        lap1 = self.nodes[0]
        lap2 = self.nodes[1]

        for i, expected_name in enumerate(['report.docx', 'report (1).docx', 'report (2).docx']):
            tid = f'tx-dup-{i}'
            content = f'Report version {i}'.encode()
            offer = {
                'transfer_id': tid,
                'sender_id': lap2.node_id,
                'sender_name': lap2.name,
                'file_name': 'report.docx',
                'file_size': len(content),
                'sha256': hashlib.sha256(content).hexdigest()
            }
            req = urllib.request.Request(
                f"http://127.0.0.1:{lap1.http_port}/api/p2p/offer",
                data=json.dumps(offer).encode('utf-8'),
                headers={'Content-Type': 'application/json'}
            )
            urllib.request.urlopen(req)

            stream = urllib.request.Request(
                f"http://127.0.0.1:{lap1.http_port}/api/p2p/stream",
                data=content,
                headers={'X-Transfer-Id': tid, 'Content-Length': str(len(content))}
            )
            urllib.request.urlopen(stream)

            saved = lap1.save_dir / expected_name
            self.assertTrue(saved.exists(), f"Expected {expected_name} to exist")
            self.assertEqual(saved.read_bytes(), content)

    def test_06_path_traversal_sanitization(self):
        """Filename with path traversal attempts ('../../hack.sh') is safely sanitized."""
        lap1 = self.nodes[0]
        lap3 = self.nodes[2]

        tid = 'tx-traversal-1'
        content = b'echo hacked'
        offer = {
            'transfer_id': tid,
            'sender_id': lap3.node_id,
            'sender_name': lap3.name,
            'file_name': '../../hack.sh',
            'file_size': len(content),
            'sha256': hashlib.sha256(content).hexdigest()
        }
        req = urllib.request.Request(
            f"http://127.0.0.1:{lap1.http_port}/api/p2p/offer",
            data=json.dumps(offer).encode('utf-8'),
            headers={'Content-Type': 'application/json'}
        )
        urllib.request.urlopen(req)

        stream = urllib.request.Request(
            f"http://127.0.0.1:{lap1.http_port}/api/p2p/stream",
            data=content,
            headers={'X-Transfer-Id': tid, 'Content-Length': str(len(content))}
        )
        urllib.request.urlopen(stream)

        # File must land inside lap1.save_dir as 'hack.sh', not in parent directory
        self.assertTrue((lap1.save_dir / 'hack.sh').exists())
        self.assertFalse((lap1.save_dir.parent / 'hack.sh').exists())

    def test_07_peer_offline_ttl_expiry(self):
        """When a node disconnects, its presence expires after TTL and peers count decreases."""
        phone2 = self.nodes[4]
        # Simulate Phone 2 closing: age out its last_seen on all other nodes
        for node in self.nodes[:4]:
            if phone2.node_id in node.peers:
                node.peers[phone2.node_id]['last_seen'] = time.time() - 30
            node.prune_peers()

        # Check Laptop 1: should now see only 3 peers instead of 4
        req = urllib.request.Request(f"http://127.0.0.1:{self.nodes[0].http_port}/api/status")
        with urllib.request.urlopen(req) as resp:
            data = json.loads(resp.read().decode('utf-8'))
            peers = data['peers']
            self.assertEqual(len(peers), 3, "Laptop 1 should now see 3 peers after Phone 2 expired")
            peer_names = [p['name'] for p in peers]
            self.assertNotIn('Phone 2', peer_names)

if __name__ == '__main__':
    unittest.main()
