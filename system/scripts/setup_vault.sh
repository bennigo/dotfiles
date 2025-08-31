#!/bin/bash

# Script to set up Ansible Vault for credentials using pass
# Usage: ./setup_vault.sh

echo "Setting up Ansible Vault with pass integration..."

# Check if pass is available
if ! command -v pass >/dev/null 2>&1; then
    echo "Error: pass is not installed. Install it first:"
    echo "  sudo apt install pass  # or your distro's package manager"
    exit 1
fi

# Check if pass is initialized
if ! pass ls >/dev/null 2>&1; then
    echo "Pass is not initialized. You need to set it up first:"
    echo "1. Generate a GPG key if you don't have one:"
    echo "   gpg --full-generate-key"
    echo "2. Initialize pass with your GPG key ID:"
    echo "   pass init <your-gpg-key-id>"
    echo "3. Run this script again"
    exit 1
fi

# Create the ansible vault password in pass
echo "Setting up Ansible Vault password in pass..."
if ! pass show ansible/vault >/dev/null 2>&1; then
    echo "Creating password entry for ansible vault..."
    echo ""
    echo "Password strength recommendations:"
    echo "- Minimum 16 characters"
    echo "- Mix of letters, numbers, and symbols"
    echo "- Avoid dictionary words"
    echo "- Consider using a passphrase (4+ random words)"
    echo ""
    echo "You'll be prompted to enter your vault password:"
    pass insert ansible/vault
else
    echo "Ansible vault password already exists in pass"
fi

# Create a YAML structure for the credentials
echo "Creating credentials YAML structure..."
cat > credentials_template.yml << 'EOF'
# Credentials vault - encrypted with ansible-vault
credentials:
  # Email and basic logins
  afreksnefnd_email: ""
  azores_login: ""
  benedikt_klifursamband_login: ""
  flug_myidtravel: ""
  google_oauth_client: ""
  launaskjal: ""
  openai_nvim_key: ""
  pgdev_vedur_is: ""
  verslo_fjarnam: ""
  
  # JSON files (store as multiline strings)
  client_secret_google: ""
  connections_json: ""

# SSH Keys (store as multiline strings)
ssh_keys:
  # Add your SSH keys here as base64 or multiline strings
  
EOF

echo "Template created as credentials_template.yml"
echo ""

# Set up environment variable for easy use
VAULT_SCRIPT="$(pwd)/scripts/ansible-vault-pass.sh"
echo "Setting up environment..."
echo "export ANSIBLE_VAULT_PASSWORD_FILE='$VAULT_SCRIPT'" >> ~/.zshrc || echo "export ANSIBLE_VAULT_PASSWORD_FILE='$VAULT_SCRIPT'" >> ~/.bashrc
echo ""
echo "Setup complete! Next steps:"
echo "1. Copy credentials automatically: python3 scripts/copy_credentials.py"
echo "2. Encrypt: ansible-vault encrypt --vault-password-file ./scripts/ansible-vault-pass.sh credentials_populated.yml"
echo "3. Rename: mv credentials_populated.yml credentials.vault"
echo "4. Add credentials.vault to git"
echo ""
echo "Useful commands (password retrieved automatically from pass):"
echo "  Decrypt: ansible-vault decrypt --vault-password-file ./scripts/ansible-vault-pass.sh credentials.vault"
echo "  Edit:    ansible-vault edit --vault-password-file ./scripts/ansible-vault-pass.sh credentials.vault"
echo "  View:    ansible-vault view --vault-password-file ./scripts/ansible-vault-pass.sh credentials.vault"
echo ""
echo "Or use the environment variable (restart shell first):"
echo "  ansible-vault edit credentials.vault"