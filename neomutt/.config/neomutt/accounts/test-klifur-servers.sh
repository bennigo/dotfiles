#!/bin/bash
# Test script to find correct klifursamband.is mail servers

echo "=== Testing klifursamband.is mail servers ==="
echo

# Common mail server patterns to test
DOMAIN="klifursamband.is"
EMAIL="benedikt@${DOMAIN}"

echo "Testing common server names for $DOMAIN..."

# Test IMAP servers
echo "Testing IMAP servers:"
for server in "mail.$DOMAIN" "imap.$DOMAIN" "mx.$DOMAIN" "$DOMAIN"; do
    echo -n "  $server:993 (IMAPS)... "
    if timeout 5 openssl s_client -connect "$server:993" -quiet -verify_return_error >/dev/null 2>&1; then
        echo "✅ SSL connection successful"
    else
        echo "❌ Connection failed"
    fi
    
    echo -n "  $server:143 (IMAP)... "  
    if timeout 5 nc -z "$server" 143 >/dev/null 2>&1; then
        echo "✅ Port open"
    else
        echo "❌ Port closed/filtered"
    fi
done

echo
echo "Testing SMTP servers:"
for server in "mail.$DOMAIN" "smtp.$DOMAIN" "mx.$DOMAIN" "$DOMAIN"; do
    echo -n "  $server:465 (SMTPS)... "
    if timeout 5 openssl s_client -connect "$server:465" -quiet -verify_return_error >/dev/null 2>&1; then
        echo "✅ SSL connection successful"  
    else
        echo "❌ Connection failed"
    fi
    
    echo -n "  $server:587 (SMTP+STARTTLS)... "
    if timeout 5 nc -z "$server" 587 >/dev/null 2>&1; then
        echo "✅ Port open"
    else
        echo "❌ Port closed/filtered"
    fi
done

echo
echo "DNS MX record lookup:"
dig MX "$DOMAIN" +short | head -3

echo
echo "=== Next steps ==="
echo "1. Find working server from tests above"
echo "2. Update account configurations with correct server names"
echo "3. Test with NeoMutt again"