import http.server, socketserver

class Handler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header('Cross-Origin-Opener-Policy', 'same-origin')
        self.send_header('Cross-Origin-Embedder-Policy', 'require-corp')
        super().end_headers()

with socketserver.TCPServer(("", 8080), Handler) as httpd:
    print("Serving at port 8080. Open http://localhost:8080 in your browser.")
    httpd.serve_forever()
