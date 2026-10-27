"""
serve.py — runs the website on your own computer for testing
-------------------------------------------------------------
From the Chillingz folder, run:
    python website/scripts/serve.py
then open http://localhost:8090 in your browser. Press Ctrl+C to stop.

It's the same as Python's built-in web server, except it tells the browser
not to keep old copies of files, so after editing a file you only need to
refresh the page to see the change.
"""

import functools
import http.server
from pathlib import Path

PORT = 8090
WEBSITE_DIR = Path(__file__).resolve().parent.parent


class NoCacheHandler(http.server.SimpleHTTPRequestHandler):
    """Serves files from the website folder and turns off browser caching."""

    def end_headers(self):
        self.send_header("Cache-Control", "no-store")
        super().end_headers()


if __name__ == "__main__":
    handler = functools.partial(NoCacheHandler, directory=str(WEBSITE_DIR))
    print(f"Website running at http://localhost:{PORT}  (Ctrl+C to stop)")
    http.server.ThreadingHTTPServer(("", PORT), handler).serve_forever()
