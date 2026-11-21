import importlib.util, json, tempfile, threading, unittest, urllib.request, urllib.error
from pathlib import Path
from http.server import ThreadingHTTPServer
spec=importlib.util.spec_from_file_location('wd_integration',Path(__file__).resolve().parents[1]/'server.py')
m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)

class FlowTest(unittest.TestCase):
    def setUp(self):
        self.tmp=tempfile.TemporaryDirectory();m.SPOOL=Path(self.tmp.name);m.access_code='123456';m.clients.clear();m.transfers.clear()
        self.httpd=ThreadingHTTPServer(('127.0.0.1',0),m.Handler)
        self.base=f'http://127.0.0.1:{self.httpd.server_port}'
        self.thread=threading.Thread(target=self.httpd.serve_forever,daemon=True);self.thread.start()
    def tearDown(self):
        self.httpd.shutdown();self.httpd.server_close();self.tmp.cleanup()
    def req(self,path,data=None,creds=None,raw=False):
        headers={}
        if creds:headers={'X-Device-Id':creds['id'],'X-Session-Token':creds['token']}
        if isinstance(data,dict):headers['Content-Type']='application/json';data=json.dumps(data).encode()
        req=urllib.request.Request(self.base+path,data=data,headers=headers)
        with urllib.request.urlopen(req,timeout=10) as r:
            b=r.read();return b if raw else json.loads(b)
    def test_end_to_end(self):
        host=self.req('/api/join',{'code':'123456','name':'Laptop 1','type':'laptop'})
        phone=self.req('/api/join',{'code':'123456','name':'Phone 1','type':'phone'})
        view=self.req('/api/peers',creds=host)
        self.assertEqual(view['peers'][0]['name'],'Phone 1')
        blob=b'Selected photo content \x00\x01'
        uploaded=self.req('/api/upload?target='+host['id']+'&name=test.jpg',data=blob,creds=phone)
        tid=uploaded['id']
        reqs=self.req('/api/peers',creds=host)['transfers'];self.assertEqual(reqs[0]['status'],'pending')
        decision=self.req('/api/decision',{'id':tid,'accept':True},host)
        self.assertEqual(decision['status'],'accepted')
        got=self.req('/api/file?id='+tid+'&ticket='+decision['ticket'],raw=True)
        self.assertEqual(got,blob)
        self.assertEqual(self.req('/api/peers',creds=phone)['transfers'][0]['status'],'completed')
    def test_invalid_pin(self):
        with self.assertRaises(urllib.error.HTTPError) as cm:
            self.req('/api/join',{'code':'111111','name':'Intruder','type':'phone'})
        self.assertEqual(cm.exception.code,403)
if __name__=='__main__':unittest.main()
