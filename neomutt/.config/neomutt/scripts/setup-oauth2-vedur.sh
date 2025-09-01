#!/bin/bash
# Setup script for OAuth2 authentication with Microsoft 365

echo "=== Microsoft 365 OAuth2 Setup for NeoMutt ==="
echo

echo "STEP 1: Microsoft App Registration (requires IT help)"
echo "Your IT department needs to register an application in Azure AD with:"
echo "  - Application Type: Public client/native"
echo "  - Redirect URI: http://localhost:8080/callback"
echo "  - Required permissions:"
echo "    * https://outlook.office365.com/IMAP.AccessAsUser.All"
echo "    * https://outlook.office365.com/SMTP.Send"
echo "    * offline_access (for refresh tokens)"
echo
echo "They will provide you with a CLIENT_ID (and optionally CLIENT_SECRET)"
echo

echo "STEP 2: Update OAuth2 script with your credentials"
echo "Edit ~/.config/neomutt/scripts/oauth2-ms.py and update:"
echo "  self.client_id = \"YOUR_CLIENT_ID_FROM_IT\""
echo "  self.client_secret = \"YOUR_CLIENT_SECRET_FROM_IT\"  # If provided"
echo

echo "STEP 3: Test OAuth2 authentication"
echo "Run: ~/.config/neomutt/scripts/oauth2-ms.py --auth"
echo "This will open a browser for Microsoft login"
echo

echo "STEP 4: Update NeoMutt account switching"
echo "The macro will be updated to use OAuth2 account"
echo

echo "STEP 5: Test NeoMutt connection"
echo "Run: neomutt -F ~/.config/neomutt/accounts/bgo-vedur-oauth2"
echo

echo "=== Alternative: Ask IT for these details ==="
echo "If IT can't help with app registration, ask them:"
echo "1. 'What authentication method should I use for email clients?'"
echo "2. 'Can you provide OAuth2 client credentials for NeoMutt?'"
echo "3. 'Is there a pre-registered app for email client access?'"
echo

echo "=== Current Status ==="
echo "✓ OAuth2 script created"
echo "✓ OAuth2 account configuration created"
echo "⚠ Needs CLIENT_ID from IT department"
echo "⚠ Needs initial authentication"

read -p "Do you have CLIENT_ID from IT? (y/n): " has_client_id

if [[ $has_client_id =~ ^[Yy]$ ]]; then
    read -p "Enter CLIENT_ID: " client_id
    read -p "Enter CLIENT_SECRET (optional, press Enter to skip): " client_secret
    
    # Update the OAuth2 script
    sed -i "s/YOUR_CLIENT_ID/$client_id/" ~/.config/neomutt/scripts/oauth2-ms.py
    if [[ -n "$client_secret" ]]; then
        sed -i "s/YOUR_CLIENT_SECRET/$client_secret/" ~/.config/neomutt/scripts/oauth2-ms.py
    fi
    
    echo
    echo "✓ OAuth2 script updated with your credentials"
    echo "Now run: ~/.config/neomutt/scripts/oauth2-ms.py --auth"
else
    echo
    echo "Contact your IT department with the information above."
    echo "Once you have CLIENT_ID, run this script again."
fi