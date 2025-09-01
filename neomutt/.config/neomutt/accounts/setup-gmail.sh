#!/bin/bash
# Gmail Account Setup Helper Script
# This script helps configure Gmail credentials and account settings

set -e  # Exit on any error

echo "=== Gmail Account Setup for NeoMutt ==="
echo

# Check if pass is initialized
if ! pass ls >/dev/null 2>&1; then
    echo "❌ Pass is not initialized. Please run 'pass init <your-gpg-key-id>' first."
    exit 1
fi

echo "✅ Pass is initialized and working."

# Get Gmail address
read -p "Enter your Gmail address: " GMAIL_ADDRESS

if [[ ! "$GMAIL_ADDRESS" =~ ^[a-zA-Z0-9._%+-]+@gmail\.com$ ]]; then
    echo "❌ Please enter a valid Gmail address ending with @gmail.com"
    exit 1
fi

echo
echo "📝 Next steps for Gmail setup:"
echo
echo "1. Go to https://myaccount.google.com/security"
echo "2. Turn on 2-factor authentication if not already enabled"
echo "3. Go to https://myaccount.google.com/apppasswords"
echo "4. Generate an App Password for 'Mail'"
echo "5. When you have the 16-character app password, come back here"
echo
read -p "Press Enter when you have your Gmail App Password ready..."

echo
echo "Enter your Gmail App Password (Google shows it as 'xxxx xxxx xxxx xxxx' - paste exactly as shown):"
read -s -p "App Password: " APP_PASSWORD_RAW
echo

# Remove all spaces from the password
APP_PASSWORD=$(echo "$APP_PASSWORD_RAW" | tr -d ' ')

if [[ ${#APP_PASSWORD} -ne 16 ]]; then
    echo "❌ After removing spaces, password should be exactly 16 characters"
    echo "   You entered ${#APP_PASSWORD} characters after space removal"
    echo "   Make sure you copied the complete App Password from Google"
    exit 1
fi

# Store password in pass
echo "$APP_PASSWORD" | pass insert -e email/gmail
echo "✅ Gmail password stored in pass"

# Clear password variables
unset APP_PASSWORD APP_PASSWORD_RAW

# Update account configuration
ACCOUNT_FILE="$HOME/.config/neomutt/accounts/gmail"
if [ -f "$ACCOUNT_FILE" ]; then
    # Create backup
    cp "$ACCOUNT_FILE" "${ACCOUNT_FILE}.backup"
    
    # Update email addresses
    sed -i "s/your-gmail@gmail.com/$GMAIL_ADDRESS/g" "$ACCOUNT_FILE"
    echo "✅ Account configuration updated: $ACCOUNT_FILE"
fi

echo
echo "🎉 Gmail account setup complete!"
echo
echo "Test the configuration:"
echo "  neomutt -F ~/.config/neomutt/neomuttrc"
echo
echo "If you have issues:"
echo "  1. Verify App Password: pass show email/gmail"
echo "  2. Check Gmail settings allow IMAP access"
echo "  3. View logs: tail -f ~/.cache/neomutt/debug"