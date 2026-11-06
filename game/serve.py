"""Local-only launcher. Binds successfully before opening the browser."""
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from functools import partial
import webbrowser

root = Path(__file__).resolve().parent.parent
address = ('127.0.0.1', 8937)
if __name__ == '__main__':
    try:
        server = ThreadingHTTPServer(address, partial(SimpleHTTPRequestHandler, directory=str(root)))
    except OSError as error:
        print(f'Cannot start game server: {error}')
        print('Port 8937 may already be in use. Close the previous game server or choose another port.')
        raise SystemExit(1)
    print('School & Sprout: http://127.0.0.1:8937')
    print('Keep this window open. Press Ctrl+C to stop.')
    webbrowser.open('http://127.0.0.1:8937')
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()
