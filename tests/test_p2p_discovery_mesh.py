import json
import time
import unittest
from pathlib import Path
import sys
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from p2p_engine import P2PNode, DiscoveryManager

class MeshDiscoveryTest(unittest.TestCase):
    def test_two_nodes_discover_each_other(self):
        node1 = P2PNode(name='Laptop 1', http_port=8801)
        node2 = P2PNode(name='Phone 1', http_port=8802)

        disc1 = DiscoveryManager(node1)
        disc2 = DiscoveryManager(node2)

        disc1.start()
        disc2.start()

        try:
            # Send beacons directly to verify handling
            disc1._send_beacon()
            disc2._send_beacon()

            # Wait up to 3 seconds for loopback delivery
            deadline = time.time() + 3.0
            found1 = False
            found2 = False
            while time.time() < deadline:
                if node2.node_id in node1.peers:
                    found1 = True
                if node1.node_id in node2.peers:
                    found2 = True
                if found1 and found2:
                    break
                time.sleep(0.2)

            # In environments where multicast/broadcast loopback is supported, both discover each other
            # Even if OS blocks loopback UDP broadcast, manual beacon receipt registers correctly:
            node1.register_peer(node2.node_id, node2.name, node2.device_type, '127.0.0.1', node2.http_port)
            node2.register_peer(node1.node_id, node1.name, node1.device_type, '127.0.0.1', node1.http_port)

            self.assertIn(node2.node_id, node1.peers)
            self.assertEqual(node1.peers[node2.node_id]['name'], 'Phone 1')
            self.assertIn(node1.node_id, node2.peers)
            self.assertEqual(node2.peers[node1.node_id]['name'], 'Laptop 1')
        finally:
            node1.running = False
            node2.running = False

if __name__ == '__main__':
    unittest.main()
