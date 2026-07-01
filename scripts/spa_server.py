# This script is replaced by eirene
# But if you are a Windows user you can use this script because 
# eirene not support windows now
import os
from http.server import SimpleHTTPRequestHandler, test

class SPARequestHandler(SimpleHTTPRequestHandler):
    def do_GET(self):
        path = self.translate_path(self.path)
        if not os.path.exists(path):
            self.path = 'index.html'
        return super().do_GET()

if __name__ == '__main__':
    test(HandlerClass=SPARequestHandler, port=8000)
