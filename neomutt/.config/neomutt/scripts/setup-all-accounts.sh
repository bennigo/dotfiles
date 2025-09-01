#!/bin/bash
# Complete Email Account Setup for NeoMutt
# Sets up all three accounts with proper credentials

set -e
CONFIG_DIR="$HOME/.config/neomutt"

echo "=== NeoMutt Multi-Account Setup ==="
echo
echo "This will set up all three email accounts:"
echo "  1. bgovedur@gmail.com (requires Gmail App Password)"
echo "  2. benedikt@klifursamband.is (using vault credentials)"
echo "  3. afreksnefnd@klifursamband.is (using vault credentials)"
echo

# Check pass is working
if ! pass ls >/dev/null 2>&1; then
    echo "❌ Pass is not initialized. Please run 'pass init <your-gpg-key-id>' first."
    exit 1
fi

echo "✅ Pass is initialized and working."

# Check if klifursamband passwords are already stored
if pass show email/benedikt-klifursamband >/dev/null 2>&1 && pass show email/afreksnefnd-klifursamband >/dev/null 2>&1; then
    echo "✅ Klifursamband account passwords already stored in pass"
else
    echo "❌ Klifursamband passwords not found in pass. They should have been imported from vault."
    echo "Please check: pass ls email/"
fi

# Gmail setup
echo
echo "📧 Setting up Gmail account..."
if pass show email/gmail >/dev/null 2>&1; then
    echo "✅ Gmail password already stored in pass"
else
    echo "Gmail requires an App Password for IMAP/SMTP access."
    echo
    echo "Steps to get Gmail App Password:"
    echo "1. Go to https://myaccount.google.com/security"
    echo "2. Enable 2-factor authentication (if not already enabled)"
    echo "3. Go to https://myaccount.google.com/apppasswords"
    echo "4. Generate an App Password for 'Mail'"
    echo "5. You'll get a 16-character password"
    echo
    read -p "Press Enter when you have your Gmail App Password ready..."
    
    echo
    echo "Enter your Gmail App Password (Google shows it as 'xxxx xxxx xxxx xxxx' - paste exactly as shown):"
    read -s -p "App Password: " GMAIL_PASSWORD_RAW
    echo
    
    # Remove all spaces from the password
    GMAIL_PASSWORD=$(echo "$GMAIL_PASSWORD_RAW" | tr -d ' ')
    
    if [[ ${#GMAIL_PASSWORD} -ne 16 ]]; then
        echo "❌ After removing spaces, password should be exactly 16 characters"
        echo "   You entered ${#GMAIL_PASSWORD} characters after space removal"
        echo "   Make sure you copied the complete App Password from Google"
        exit 1
    fi
    
    echo "$GMAIL_PASSWORD" | pass insert -e email/gmail
    echo "✅ Gmail password stored in pass"
    unset GMAIL_PASSWORD GMAIL_PASSWORD_RAW
fi

# Set Gmail as default
echo "source $CONFIG_DIR/accounts/gmail" > $CONFIG_DIR/current-account

echo
echo "🎉 Multi-account setup complete!"
echo
echo "🎯 How to use:"
echo "  Start NeoMutt: neomutt"
echo "  Switch accounts:"
echo "    Alt+1 - Gmail"
echo "    Alt+2 - benedikt@klifursamband.is"
echo "    Alt+3 - afreksnefnd@klifursamband.is"
echo
echo "  Or use script: ~/.config/neomutt/scripts/account-switch.sh [gmail|benedikt|afreksnefnd]"
echo
echo "📋 Test your setup:"
echo "  1. Run: neomutt"
echo "  2. Try connecting to Gmail first"
echo "  3. Switch accounts with Alt+2 and Alt+3"
echo "  4. Check debug log if issues: tail -f ~/.cache/neomutt/debug"