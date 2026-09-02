"""Canary pod: healthy for HEALTHY_DURATION seconds, then returns 503."""
import http.server
import os
import time

HEALTHY_DURATION = int(os.environ.get("HEALTHY_DURATION", "120"))
PORT = int(os.environ.get("PORT", "8080"))
start_time = time.time()


class Handler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        elapsed = time.time() - start_time
        if self.path == "/healthz":
            if elapsed < HEALTHY_DURATION:
                self.send_response(200)
                self.end_headers()
                self.wfile.write(b"ok")
            else:
                self.send_response(503)
                self.end_headers()
                self.wfile.write(b"degraded")
        else:
            self.send_response(200)
            self.end_headers()
            self.wfile.write(f"canary up {elapsed:.0f}s\n".encode())

    def log_message(self, format, *args):
        print(f"{self.address_string()} - {format % args}")


if __name__ == "__main__":
    server = http.server.HTTPServer(("0.0.0.0", PORT), Handler)
    print(f"Canary starting. Healthy for {HEALTHY_DURATION}s, then degrading.")
    server.serve_forever()
