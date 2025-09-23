#!/usr/bin/env python3
"""
Simple Test Server for Notification Master Plugin

This is a simple HTTP server that provides test endpoints for the notification service.
Run this server locally to test the notification polling functionality.

Usage:
    python test_server.py

The server will run on http://localhost:8080
"""

import json
import time
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs

class NotificationHandler(BaseHTTPRequestHandler):
    # Sample notifications for testing
    notifications = [
        {
            "title": "Test Notification 1",
            "message": "This is a test notification from local server",
            "channelId": "default_channel"
        },
        {
            "title": "Test Notification 2", 
            "message": "Another test notification with big text",
            "bigText": "This is an expanded text for the notification. It contains more details about the notification content.",
            "channelId": "high_priority_channel"
        },
        {
            "title": "Test Notification 3",
            "message": "Silent notification test",
            "channelId": "silent_channel"
        }
    ]
    
    current_index = 0
    
    def do_GET(self):
        """Handle GET requests"""
        parsed_path = urlparse(self.path)
        
        # Set CORS headers
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        self.send_header('Content-Type', 'application/json')
        self.end_headers()
        
        if parsed_path.path == '/api/notifications':
            # Return one notification at a time, cycling through them
            response = {'notifications': []}
            
            if self.notifications:
                notification = self.notifications[self.current_index]
                response['notifications'].append(notification)
                
                # Move to next notification for next request
                self.current_index = (self.current_index + 1) % len(self.notifications)
            
            self.wfile.write(json.dumps(response).encode())
            
        elif parsed_path.path == '/api/status':
            # Status endpoint
            response = {
                'status': 'ok',
                'server': 'notification_test_server',
                'time': time.time(),
                'available_notifications': len(self.notifications)
            }
            self.wfile.write(json.dumps(response).encode())
            
        else:
            # 404 for other paths
            self.send_response(404)
            self.end_headers()
            self.wfile.write(b'{"error": "Not found"}')
    
    def do_OPTIONS(self):
        """Handle OPTIONS requests for CORS"""
        self.send_response(204)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        self.end_headers()
    
    def log_message(self, format, *args):
        """Custom log format"""
        print(f"[{time.strftime('%Y-%m-%d %H:%M:%S')}] {format % args}")

def run_server(port=8080):
    """Run the test server"""
    server_address = ('', port)
    httpd = HTTPServer(server_address, NotificationHandler)
    
    print(f"Starting notification test server on port {port}")
    print(f"Test URL: http://localhost:{port}/api/notifications")
    print(f"Status URL: http://localhost:{port}/api/status")
    print("Press Ctrl+C to stop the server")
    
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nShutting down server...")
        httpd.shutdown()

if __name__ == '__main__':
    run_server()