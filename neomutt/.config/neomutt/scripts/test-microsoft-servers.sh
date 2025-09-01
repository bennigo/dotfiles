#!/bin/bash
# Test script to determine Microsoft/Outlook server settings for vedur.is

EMAIL="bgo@vedur.is"

echo "=== Testing Microsoft/Outlook Server Settings for vedur.is ==="
echo "Account: $EMAIL"
echo

echo "1. Testing Outlook.com servers (most common)..."
echo "   IMAP: outlook.office365.com:993"
echo "   SMTP: smtp.office365.com:587"
timeout 5 curl -s --url "imaps://outlook.office365.com:993/" --user "$EMAIL:" 2>&1 | head -3
echo

echo "2. Testing Exchange Online servers..."
echo "   IMAP: imap.office365.com:993" 
echo "   SMTP: smtp.office365.com:587"
timeout 5 curl -s --url "imaps://imap.office365.com:993/" --user "$EMAIL:" 2>&1 | head -3
echo

echo "3. Testing legacy Exchange servers..."
echo "   IMAP: mail.vedur.is:993"
echo "   SMTP: mail.vedur.is:587"
timeout 5 curl -s --url "imaps://mail.vedur.is:993/" --user "$EMAIL:" 2>&1 | head -3
echo

echo "=== Server Discovery Results ==="
echo "Look for responses that show connection attempts vs immediate failures"
echo "Successful connections will show IMAP greeting or authentication prompts"
echo

echo "=== Authentication Notes ==="
echo "Microsoft 365 typically uses:"
echo "- Modern Authentication (OAuth2) - preferred"
echo "- App Passwords (if enabled by admin)"
echo "- Basic Authentication (often disabled)"
echo
echo "Check with IT admin about:"
echo "1. Are App Passwords enabled for your tenant?"
echo "2. Is Basic Authentication allowed?"
echo "3. What are the exact server settings?"