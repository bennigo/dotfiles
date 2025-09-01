#!/bin/bash
# Test script to verify vedur.is password

EMAIL="bgo@vedur.is"

echo "=== Testing Vedur.is Password ==="
echo "Account: $EMAIL"
echo

echo "1. Password stored in pass:"
echo "Length: $(pass show email/bgo-vedur | wc -c) characters (including newline)"
echo "Format: $(pass show email/bgo-vedur | tr -d '\n' | sed 's/./*/g')"
echo

echo "2. Testing IMAP connection with curl..."
timeout 10 curl -v --url "imaps://outlook.office365.com:993/" \
    --user "$EMAIL:$(pass show email/bgo-vedur)" \
    --request "SELECT INBOX" 2>&1 | grep -E "(Login|Auth|denied|failed|success|OK)"
echo

echo "3. Testing SMTP connection..."
timeout 10 curl -v --url "smtps://smtp.office365.com:587/" \
    --user "$EMAIL:$(pass show email/bgo-vedur)" \
    --mail-from "$EMAIL" 2>&1 | grep -E "(Login|Auth|denied|failed|success|OK)"
echo

echo "=== Troubleshooting Steps ==="
echo "If authentication fails:"
echo "1. Verify password: pass edit email/bgo-vedur"
echo "2. Check if MFA/2FA is enabled on your account"
echo "3. Microsoft may require App Passwords instead of regular password"
echo "4. Contact IT admin about authentication requirements"