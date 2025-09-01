#!/usr/bin/env python3
"""
OAuth2 authentication script for Microsoft 365 with NeoMutt
Handles token acquisition and refresh for IMAP/SMTP access
"""

import json
import sys
import os
import time
import webbrowser
import urllib.parse
import urllib.request
import base64
import hashlib
import secrets
from http.server import HTTPServer, BaseHTTPRequestHandler
import threading

class OAuth2Handler:
    def __init__(self):
        # Microsoft 365 OAuth2 endpoints
        self.tenant_id = "common"  # Use "common" for multi-tenant apps
        self.client_id = "d3590ed6-52b3-4102-aeff-aad2292ab01c"  # Microsoft public client for mail access
        self.client_secret = "YOUR_CLIENT_SECRET"  # Optional for public clients
        self.redirect_uri = "http://localhost:8080/callback"
        self.scope = "https://outlook.office365.com/IMAP.AccessAsUser.All https://outlook.office365.com/SMTP.Send offline_access"
        
        self.auth_url = f"https://login.microsoftonline.com/{self.tenant_id}/oauth2/v2.0/authorize"
        self.token_url = f"https://login.microsoftonline.com/{self.tenant_id}/oauth2/v2.0/token"
        
        self.token_file = os.path.expanduser("~/.cache/neomutt/oauth2_tokens.json")
        
    def load_tokens(self):
        """Load existing tokens from file"""
        try:
            with open(self.token_file, 'r') as f:
                return json.load(f)
        except (FileNotFoundError, json.JSONDecodeError):
            return None
    
    def save_tokens(self, tokens):
        """Save tokens to file"""
        os.makedirs(os.path.dirname(self.token_file), exist_ok=True)
        with open(self.token_file, 'w') as f:
            json.dump(tokens, f, indent=2)
        os.chmod(self.token_file, 0o600)  # Secure permissions
    
    def generate_pkce(self):
        """Generate PKCE code verifier and challenge"""
        code_verifier = base64.urlsafe_b64encode(secrets.token_bytes(32)).decode('utf-8').rstrip('=')
        code_challenge = base64.urlsafe_b64encode(
            hashlib.sha256(code_verifier.encode('utf-8')).digest()
        ).decode('utf-8').rstrip('=')
        return code_verifier, code_challenge
    
    def get_auth_url(self, code_challenge):
        """Generate authorization URL"""
        params = {
            'client_id': self.client_id,
            'response_type': 'code',
            'redirect_uri': self.redirect_uri,
            'scope': self.scope,
            'code_challenge': code_challenge,
            'code_challenge_method': 'S256',
            'state': secrets.token_urlsafe(32)
        }
        return f"{self.auth_url}?{urllib.parse.urlencode(params)}"
    
    def exchange_code_for_tokens(self, code, code_verifier):
        """Exchange authorization code for tokens"""
        data = {
            'client_id': self.client_id,
            'grant_type': 'authorization_code',
            'code': code,
            'redirect_uri': self.redirect_uri,
            'code_verifier': code_verifier
        }
        
        if self.client_secret:
            data['client_secret'] = self.client_secret
        
        req = urllib.request.Request(
            self.token_url,
            data=urllib.parse.urlencode(data).encode('utf-8'),
            headers={'Content-Type': 'application/x-www-form-urlencoded'}
        )
        
        try:
            with urllib.request.urlopen(req) as response:
                return json.loads(response.read().decode('utf-8'))
        except Exception as e:
            print(f"Token exchange failed: {e}", file=sys.stderr)
            return None
    
    def refresh_tokens(self, refresh_token):
        """Refresh access token using refresh token"""
        data = {
            'client_id': self.client_id,
            'grant_type': 'refresh_token',
            'refresh_token': refresh_token,
            'scope': self.scope
        }
        
        if self.client_secret:
            data['client_secret'] = self.client_secret
        
        req = urllib.request.Request(
            self.token_url,
            data=urllib.parse.urlencode(data).encode('utf-8'),
            headers={'Content-Type': 'application/x-www-form-urlencoded'}
        )
        
        try:
            with urllib.request.urlopen(req) as response:
                return json.loads(response.read().decode('utf-8'))
        except Exception as e:
            print(f"Token refresh failed: {e}", file=sys.stderr)
            return None
    
    def get_access_token(self):
        """Get valid access token, refreshing if necessary"""
        tokens = self.load_tokens()
        
        if not tokens:
            print("No tokens found. Run with --auth to authenticate.", file=sys.stderr)
            return None
        
        # Check if token is expired (with 5-minute buffer)
        expires_at = tokens.get('expires_at', 0)
        if time.time() > (expires_at - 300):
            # Token expired, try to refresh
            new_tokens = self.refresh_tokens(tokens.get('refresh_token'))
            if new_tokens:
                new_tokens['expires_at'] = time.time() + new_tokens.get('expires_in', 3600)
                self.save_tokens(new_tokens)
                return new_tokens['access_token']
            else:
                print("Token refresh failed. Re-authentication required.", file=sys.stderr)
                return None
        
        return tokens['access_token']
    
    def authenticate(self):
        """Perform initial authentication flow"""
        print("=== Microsoft 365 OAuth2 Authentication ===")
        print("This will open a browser for authentication...")
        
        code_verifier, code_challenge = self.generate_pkce()
        auth_url = self.get_auth_url(code_challenge)
        
        # Start local server to receive callback
        callback_received = threading.Event()
        auth_code = None
        
        class CallbackHandler(BaseHTTPRequestHandler):
            def do_GET(self):
                nonlocal auth_code
                if self.path.startswith('/callback'):
                    query = urllib.parse.parse_qs(urllib.parse.urlparse(self.path).query)
                    auth_code = query.get('code', [None])[0]
                    
                    if auth_code:
                        self.send_response(200)
                        self.send_header('Content-type', 'text/html')
                        self.end_headers()
                        self.wfile.write(b'<html><body><h1>Authentication successful!</h1><p>You can close this window.</p></body></html>')
                    else:
                        self.send_response(400)
                        self.send_header('Content-type', 'text/html')
                        self.end_headers()
                        self.wfile.write(b'<html><body><h1>Authentication failed!</h1></body></html>')
                    
                    callback_received.set()
            
            def log_message(self, format, *args):
                pass  # Suppress log output
        
        server = HTTPServer(('localhost', 8080), CallbackHandler)
        server_thread = threading.Thread(target=server.serve_forever)
        server_thread.daemon = True
        server_thread.start()
        
        print(f"Opening browser: {auth_url}")
        webbrowser.open(auth_url)
        
        print("Waiting for authentication...")
        callback_received.wait(timeout=300)  # 5-minute timeout
        server.shutdown()
        
        if not auth_code:
            print("Authentication failed or timed out.", file=sys.stderr)
            return False
        
        # Exchange code for tokens
        tokens = self.exchange_code_for_tokens(auth_code, code_verifier)
        if not tokens:
            return False
        
        # Save tokens with expiration time
        tokens['expires_at'] = time.time() + tokens.get('expires_in', 3600)
        self.save_tokens(tokens)
        
        print("Authentication successful! Tokens saved.")
        return True

def main():
    if len(sys.argv) < 2:
        print("Usage: oauth2-ms.py --auth|--token", file=sys.stderr)
        sys.exit(1)
    
    handler = OAuth2Handler()
    
    if sys.argv[1] == '--auth':
        if not handler.authenticate():
            sys.exit(1)
    elif sys.argv[1] == '--token':
        token = handler.get_access_token()
        if token:
            print(token)
        else:
            sys.exit(1)
    else:
        print("Invalid argument. Use --auth or --token", file=sys.stderr)
        sys.exit(1)

if __name__ == '__main__':
    main()