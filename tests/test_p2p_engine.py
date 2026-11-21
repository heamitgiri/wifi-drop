import hashlib
import json
import tempfile
import threading
import time
import unittest
from pathlib import Path
from http.server import ThreadingHTTPServer
import urllib.request

import sys
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from p2p_engine import P2PNode, HTTPHandler

class P2PEngineUnitTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.node = P2PNode(name='TestNode', http_port=9876, save_dir=self.tmp.name)

    def tearDown(self):
        self.tmp.cleanup()

    def test_sanitize_filename(self):
        self.assertEqual(self.node.sanitize_filename('../../secret.pem'), 'secret.pem')
        self.assertEqual(self.node.sanitize_filename('nested/dir/my<video>.mp4'), 'myvideo.mp4')
        self.assertEqual(self.node.sanitize_filename('....'), 'unnamed_file')

    def test_safe_destination_collision(self):
        dest1 = self.node.get_safe_destination('sample.txt')
        self.assertEqual(dest1.name, 'sample.txt')
        dest1.write_text('content 1')

        dest2 = self.node.get_safe_destination('sample.txt')
        self.assertEqual(dest2.name, 'sample (1).txt')
        dest2.write_text('content 2')

        dest3 = self.node.get_safe_destination('sample.txt')
        self.assertEqual(dest3.name, 'sample (2).txt')

    def test_peer_registration_and_prune(self):
        self.node.register_peer('peer-1', 'Laptop 2', 'laptop', '192.168.1.15', 8765)
        self.assertIn('peer-1', self.node.peers)
        self.assertEqual(self.node.peers['peer-1']['name'], 'Laptop 2')

        # Fake time lapse to test pruning
        self.node.peers['peer-1']['last_seen'] = time.time() - 30
        self.node.prune_peers()
        self.assertNotIn('peer-1', self.node.peers)

class P2PEndToEndTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.node = P2PNode(name='ReceiverNode', http_port=0, save_dir=self.tmp.name)
        self.node.ask_before_receiving = False  # Auto-accept for integration test

        class CustomServer(ThreadingHTTPServer):
            pass
        self.server = CustomServer(('127.0.0.1', 0), HTTPHandler)
        self.server.node = self.node
        self.port = self.server.server_port
        self.base_url = f"http://127.0.0.1:{self.port}"
        self.thread = threading.Thread(target=self.server.serve_forever, daemon=True)
        self.thread.start()

    def tearDown(self):
        self.server.shutdown()
        self.server.server_close()
        self.tmp.cleanup()

    def test_status_endpoint(self):
        req = urllib.request.Request(f"{self.base_url}/api/status")
        with urllib.request.urlopen(req) as resp:
            data = json.loads(resp.read().decode('utf-8'))
            self.assertEqual(data['me']['name'], 'ReceiverNode')

    def test_p2p_offer_and_stream(self):
        # 1. Offer
        payload = {
            'transfer_id': 'tx-123',
            'sender_id': 'sender-abc',
            'sender_name': 'Sender Laptop',
            'file_name': 'document.txt',
            'file_size': 12,
            'sha256': hashlib.sha256(b'Hello World!').hexdigest()
        }
        offer_req = urllib.request.Request(
            f"{self.base_url}/api/p2p/offer",
            data=json.dumps(payload).encode('utf-8'),
            headers={'Content-Type': 'application/json'}
        )
        with urllib.request.urlopen(offer_req) as resp:
            data = json.loads(resp.read().decode('utf-8'))
            self.assertTrue(data['accepted'])

        # 2. Stream
        stream_req = urllib.request.Request(
            f"{self.base_url}/api/p2p/stream",
            data=b'Hello World!',
            headers={
                'X-Transfer-Id': 'tx-123',
                'Content-Length': '12'
            }
        )
        with urllib.request.urlopen(stream_req) as resp:
            data = json.loads(resp.read().decode('utf-8'))
            self.assertEqual(data['status'], 'completed')

        # 3. Verify file on disk
        saved_file = Path(self.tmp.name) / 'document.txt'
        self.assertTrue(saved_file.exists())
        self.assertEqual(saved_file.read_bytes(), b'Hello World!')

if __name__ == '__main__':
    unittest.main()
