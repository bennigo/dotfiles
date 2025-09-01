#!/bin/bash
# Test script to verify account switching functionality

echo "=== Testing NeoMutt Account Switching ==="
echo

echo "1. Testing Gmail account connection..."
timeout 10 neomutt -F ~/.config/neomutt/accounts/gmail -e 'push ":set debug_level=0<enter>:exec check-stats<enter>:quit<enter>"'
echo "Gmail test completed"
echo

echo "2. Testing Benedikt@klifursamband account connection..."  
timeout 10 neomutt -F ~/.config/neomutt/accounts/benedikt-klifursamband -e 'push ":set debug_level=0<enter>:exec check-stats<enter>:quit<enter>"'
echo "Benedikt@klifursamband test completed"
echo

echo "3. Testing Afreksnefnd@klifursamband account connection..."
timeout 10 neomutt -F ~/.config/neomutt/accounts/afreksnefnd-klifursamband -e 'push ":set debug_level=0<enter>:exec check-stats<enter>:quit<enter>"'
echo "Afreksnefnd@klifursamband test completed"
echo

echo "4. Testing Vedur.is account connection (via mailrelay)..."
timeout 10 neomutt -F ~/.config/neomutt/accounts/bgo-vedur-relay -e 'push ":set debug_level=0<enter>:exec check-stats<enter>:quit<enter>"'
echo "Vedur.is (relay) test completed"
echo

echo "=== Account switching test completed ==="
echo "If connections succeeded, the account switching should work properly."