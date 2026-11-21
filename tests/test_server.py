import importlib.util
from pathlib import Path
import unittest

spec=importlib.util.spec_from_file_location('wifidrop',Path(__file__).resolve().parents[1]/'server.py')
m=importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
class ValidationTests(unittest.TestCase):
    def test_filename(self):
        self.assertEqual(m.clean_name('../my<video>.mp4'),'myvideo.mp4')
    def test_empty_filename(self):
        self.assertEqual(m.clean_name('....'),'Unnamed')
    def test_name_limit(self):
        self.assertEqual(len(m.clean_name('x'*300)),75)
    def test_peer_cleanup(self):
        m.clients.clear();m.clients['old']={'seen':0,'token':'x','name':'old','type':'phone'}
        m.cleanup();self.assertEqual(m.clients,{})
if __name__=='__main__': unittest.main()
