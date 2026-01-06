#!/usr/bin/env python3
"""
HTTP server with proper Range request support for video streaming.
"""
import http.server
import socketserver
import os
import sys
from pathlib import Path

PORT = 8000

class RangeRequestHandler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        # Add headers to support range requests
        self.send_header('Accept-Ranges', 'bytes')
        self.send_header('Connection', 'close')
        super().end_headers()

    def do_GET(self):
        # Get the file path
        path = self.translate_path(self.path)
        
        # Check if file exists
        if not os.path.exists(path) or not os.path.isfile(path):
            self.send_error(404)
            return
        
        # Get file size
        file_size = os.path.getsize(path)
        
        # Check for Range header
        if 'Range' in self.headers:
            range_header = self.headers['Range']
            if not range_header.startswith('bytes='):
                self.send_error(416)
                return
            
            try:
                ranges = range_header[6:].split(',')
                range_start, range_end = ranges[0].split('-')
                range_start = int(range_start) if range_start else 0
                range_end = int(range_end) if range_end else file_size - 1
                
                if range_start >= file_size or range_end >= file_size or range_start > range_end:
                    self.send_error(416)
                    return
                
                # Send 206 Partial Content
                self.send_response(206)
                self.send_header('Content-type', self.guess_type(path))
                self.send_header('Content-Length', str(range_end - range_start + 1))
                self.send_header('Content-Range', f'bytes {range_start}-{range_end}/{file_size}')
                self.send_header('Accept-Ranges', 'bytes')
                self.end_headers()
                
                # Send the file chunk
                with open(path, 'rb') as f:
                    f.seek(range_start)
                    self.wfile.write(f.read(range_end - range_start + 1))
            except (ValueError, IndexError):
                self.send_error(416)
        else:
            # No range request, send entire file
            self.send_response(200)
            self.send_header('Content-type', self.guess_type(path))
            self.send_header('Content-Length', str(file_size))
            self.send_header('Accept-Ranges', 'bytes')
            self.end_headers()
            
            with open(path, 'rb') as f:
                self.wfile.write(f.read())

    def log_message(self, format, *args):
        # Log requests
        sys.stderr.write(f"[{self.log_date_time_string()}] {format % args}\n")

if __name__ == '__main__':
    os.chdir(Path(__file__).parent)
    with socketserver.TCPServer(("", PORT), RangeRequestHandler) as httpd:
        print(f"Server running at http://localhost:{PORT}/")
        print("Press Ctrl+C to stop")
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\nServer stopped")
