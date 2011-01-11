""" Version of ipy_vimserver with simplified connectivity """
""" The original version uses low-level socket functions which are not portabel (windows). Therefore this version was born with standarized xml-rpc connection.
It should provide the same functionality, just more portable (I hope).

Creates a new thread containing a SimpleXMLRPCServer. This server exposes the send(cmd) command which in turn passes lines to ipython.



"""

import IPython.ipapi
from SimpleXMLRPCServer import SimpleXMLRPCServer
import os, threading, subprocess

global SERVER
SERVER = None # this will become the server port number
#ip = IPython.ipapi.get()  # initialize connection to IPython

class IpyServerXMLRPC(threading.Thread):
    def __init__(self, port=9876, logging = False):
        """ Simple creation of the XMLRPC server in a separate thread"""
        super(IpyServerXMLRPC, self).__init__()
        self.setDaemon(True)
        self.server = SimpleXMLRPCServer(("localhost",port),logRequests=logging)
        self.server.register_function(self.send)
        self.server.register_function(self.test_pylab)
        if logging:
            print "setup complete at: %s port %d" % self.get_socket_name()

    def run(self):
        """ The main worker of the threa. No separate loop as it is already present in serve_forever()""" 
        self.server.serve_forever()

    def send(self,data):
        """ Gets the data from vim and splits it in parts (just in case). Passes to ipython.
        Returns the number of lines being pasted to ipython"""
        data = data.split('\n')
        cmds = list()
        for line in data:
            cmds.append(line)
        ip=IPython.ipapi.get()
        ip.runlines(cmds)
        return len(cmds)
    def test_pylab(self):
        ip=IPython.ipapi.get()
        ip.runlines('a = logspace(1,10,101)')
        ip.runlines('print a')

    def kill(self):
        """ Kills the server. Should be run from a separate thread, such as the ipython thread.
        """
        print 'shutting down vim server'
        self.server.shutdown()
        raise IPython.ipapi.TryNext 
    def get_socket_name(self):
        return self.server.socket.getsockname()

def shutdown(self):
    """ Shuts down the server. 
        Not exactly sure why this simple wrapper is needed though... 
    """
    if SERVER:
        SERVER.kill()

def setup(port = 0,logging = False,fork = True):
    """ Sets up the connection. In practice it starts the server 
        on a first available port (therefore the 0).
    """
    
    global SERVER
    if not SERVER:
        SERVER = IpyServerXMLRPC(port=port,logging = logging)
        ip.set_hook('shutdown_hook', shutdown, 10)
        socketname = SERVER.get_socket_name()
        vimhook.vimserver = "IPYS_RPC"
        vimhook.ipyserver = socketname
        SERVER.start()


# calls gvim, with all ops happening on the correct gvim instance for this
# ipython instance. it then calls edit -x (since gvim will return right away)
# things of note: it sets up a special environment, so that the ipy.vim script
# can connect back to the ipython instance and do fun things, like run the file
def vimhook(self, fname, line):
    env = os.environ.copy()
    vserver = vimhook.vimserver.upper()
    check = subprocess.Popen('gvim --serverlist', stdout = subprocess.PIPE,
        shell=True)
    check.wait()
    cval = [l for l in check.stdout.readlines() if vserver in l]

    if cval:
        vimargs = '--remote%s' % (vimhook.extras,)
    else:
        vimargs = ''
    vimhook.extras = ''

    env['IPY_SESSION'] = vimhook.vimserver
    env['IPY_SERVER'] = 'http://%s:%d'%vimhook.ipyserver

    if line is None: line = ''
    else: line = '+' + line
    vim_cmd = 'gvim --servername %s %s %s %s' % (vimhook.vimserver, vimargs,
        line, fname)
    subprocess.call(vim_cmd, env=env, shell=True)


#default values to keep it sane...
vimhook.vimserver = ''
vimhook.ipyserver = ''

ip.set_hook('editor',vimhook)



