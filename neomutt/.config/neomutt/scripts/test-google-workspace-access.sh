#!/bin/bash
# Test script to check Google Workspace account access and capabilities

EMAIL="benedikt@klifursamband.is"

echo "=== Testing Google Workspace Account Access ==="
echo "Account: $EMAIL"
echo

echo "1. Testing basic IMAP authentication with current password..."
timeout 10 curl -s --url "imaps://imap.gmail.com:993/INBOX" \
    --user "$EMAIL:$(pass show email/benedikt-klifursamband)" \
    --request "SELECT INBOX" 2>&1 | head -5

echo
echo "2. Checking if 2FA is required..."
# Try to access Google account settings page
echo "   You can check manually by going to:"
echo "   https://myaccount.google.com/security"
echo "   (Log in with $EMAIL)"

echo
echo "3. Checking App Password access..."
echo "   Try to access: https://myaccount.google.com/apppasswords"
echo "   - If you see 'App passwords', you can generate them"
echo "   - If you see 'This setting is not available', admin controls it"
echo "   - If you can't access, 2FA might not be enabled"

echo
echo "4. Testing SMTP authentication..."
timeout 10 curl -s --url "smtps://smtp.gmail.com:465" \
    --mail-from "$EMAIL" \
    --user "$EMAIL:$(pass show email/benedikt-klifursamband)" 2>&1 | head -3

echo
echo "=== Results interpretation ==="
echo "- If IMAP/SMTP work: Regular password authentication is enabled"
echo "- If they fail with auth error: Need App Password or 2FA setup"
echo "- If timeout: Network/server issue"
echo
echo "=== Manual tests to try ==="
echo "1. Go to https://myaccount.google.com/security with $EMAIL"
echo "2. Check if 2-step verification is ON"
echo "3. Go to https://myaccount.google.com/apppasswords"
echo "4. If available, generate App Password for 'Mail'"
echo "5. If not available, contact admin or try asking for access"