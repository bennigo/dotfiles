# Secure Credentials Management with Ansible Vault and Pass

This document describes the complete setup and workflow for managing sensitive credentials securely using Ansible Vault encryption with `pass` password manager integration.

## Overview

This system provides:
- **Secure encryption** of credentials using Ansible Vault (AES256)
- **GPG-based password management** using `pass` (no plaintext passwords)
- **Git-safe storage** - encrypted files can be safely committed
- **Easy access** - automated password retrieval from `pass`

## Prerequisites

### Required Tools
```bash
# Install required packages
sudo apt install pass ansible gpg

# Verify installations
pass --version
ansible-vault --version
gpg --version
```

### GPG Key Setup
```bash
# Generate a new GPG key (recommended: Ed25519)
gpg --full-generate-key
# Choose: (9) ECC and ECC, then (1) Curve 25519
# Set expiration: 2-5 years
# Use strong passphrase

# Verify key creation
gpg --list-secret-keys --keyid-format LONG
```

### Pass Initialization
```bash
# Initialize pass with your GPG key ID
pass init <YOUR-GPG-KEY-ID>

# Example:
# pass init F6DABA801ABD669C
```

## Complete Setup Procedure

### Step 1: Run Setup Script
```bash
cd ~/.dotfiles/system/
./scripts/setup_vault.sh
```

This script will:
- Verify all prerequisites
- Create vault password in `pass` (stored as `ansible/vault`)
- Generate credentials template file
- Set up environment variables

### Step 2: Copy Credentials
The setup automatically copies your existing credentials from `.credentials_and_logins/` to a YAML structure:

```bash
# This happens automatically via the copy script
./scripts/copy_credentials.py
```

Handles these credential types:
- Text files (login info, API keys, etc.)
- JSON files (OAuth secrets, connection strings)  
- SSH keys and configuration
- Binary files (base64 encoded)

### Step 3: Encrypt Credentials
```bash
# Encrypt the populated credentials file
ansible-vault encrypt --vault-password-file ./scripts/ansible-vault-pass.sh credentials_populated.yml

# Rename to final vault file
mv credentials_populated.yml credentials.vault
```

### Step 4: Verify Setup
```bash
# Test decryption (should show your credentials)
ansible-vault view --vault-password-file ./scripts/ansible-vault-pass.sh credentials.vault | head -10

# Verify vault file properties
file credentials.vault
# Should show: "Ansible Vault, version 1.1, encryption AES256"
```

## Daily Usage

### Viewing Credentials
```bash
# View entire vault
ansible-vault view --vault-password-file ./scripts/ansible-vault-pass.sh credentials.vault

# View specific sections
ansible-vault view --vault-password-file ./scripts/ansible-vault-pass.sh credentials.vault | grep -A 5 "openai_nvim_key"
```

### Editing Credentials
```bash
# Edit vault (opens in your default editor)
ansible-vault edit --vault-password-file ./scripts/ansible-vault-pass.sh credentials.vault

# Or use environment variable (if set by setup script)
ansible-vault edit credentials.vault
```

### Adding New Credentials

**Interactive Method (Recommended):**
```bash
# Guided credential addition with safety checks
./scripts/add-credentials.sh
```

**Quick Edit Method:**
```bash
# Direct vault editing (opens in your default editor)
ansible-vault edit --vault-password-file ./scripts/ansible-vault-pass.sh credentials.vault

# Add new entries to the appropriate section:
# credentials:
#   new_service_key: "your-new-api-key"
#   new_login: |
#     username: myuser
#     password: mypass
# Save and exit - file remains encrypted
```

**Commit Changes:**
```bash
# Simple commit with default message
./scripts/commit-credentials.sh

# Commit with custom message
./scripts/commit-credentials.sh "Add new API credentials"
```

> 📖 **Detailed Guide**: See `add-credentials-procedure.md` for complete workflow documentation

## File Structure

```
system/
├── credentials.vault                 # Encrypted credentials (safe for git)
├── credentials.md                   # This documentation
├── add-credentials-procedure.md     # Detailed workflow guide
├── gpg_backup_strategies.md         # GPG backup guide
├── scripts/
│   ├── setup_vault.sh              # Main setup script
│   ├── ansible-vault-pass.sh       # Password retrieval script
│   ├── copy_credentials.py         # Credentials migration script
│   ├── add-credentials.sh          # Interactive credential management
│   ├── commit-credentials.sh       # Git workflow for vault changes
│   └── README.md                   # Script documentation
└── .credentials_and_logins/        # Original (excluded from git)
    ├── *.txt, *.json, *.login     # Various credential files
    └── ssh_keys/                   # SSH keys and config
```

## Security Features

### Password Security
- Vault password stored in GPG-encrypted `pass` store
- No plaintext passwords anywhere in the filesystem
- Password automatically retrieved when needed

### File Security  
- Original credentials directory excluded from git (`.gitignore`)
- Only encrypted vault file can be committed
- AES256 encryption with strong vault password

### Access Control
- Requires GPG private key access to decrypt vault password
- GPG key protected by passphrase
- Multi-layer security (GPG → pass → ansible-vault → credentials)

## Emergency and Learning Resources

**⚠️ Getting locked out?** See `emergency-recovery.md` for step-by-step recovery procedures.

**🎓 Need a GPG/Pass refresher?** See `gpg-pass-tutorial.md` for daily usage guide.

**🧠 Password memory strategy?** See `password-memory-strategy.md` for backup and memory techniques.

## Troubleshooting

### "Error: pass is not initialized"
```bash
# Check if pass is set up
pass ls

# If not, initialize with your GPG key
gpg --list-secret-keys --keyid-format LONG
pass init <YOUR-GPG-KEY-ID>
```

### "Error: Password entry 'ansible/vault' not found"
```bash
# Create the vault password manually
pass insert ansible/vault
# Enter a strong password when prompted
```

### "Error: vault password prompt failed"
```bash
# Check if script is executable
chmod +x scripts/ansible-vault-pass.sh

# Test password retrieval
./scripts/ansible-vault-pass.sh
```

### GPG Issues
```bash
# Check GPG agent is running
gpg-agent --daemon

# Test GPG functionality
echo "test" | gpg --encrypt -r your@email.com | gpg --decrypt
```

## Backup and Recovery

### What to Backup
1. **GPG keys** (see `gpg_backup_strategies.md`)
2. **Pass password store**: `~/.password-store/`
3. **Encrypted vault file**: `credentials.vault`

### Recovery Process
1. Restore GPG keys from backup
2. Restore pass password store
3. Clone dotfiles repo with `credentials.vault`
4. Decrypt vault: `ansible-vault view credentials.vault`

## Advanced Usage

### Multiple Vault Files
```bash
# Create separate vaults for different purposes
ansible-vault create --vault-password-file ./scripts/ansible-vault-pass.sh production.vault
ansible-vault create --vault-password-file ./scripts/ansible-vault-pass.sh development.vault
```

### Scripted Access
```bash
#!/bin/bash
# Extract specific credential for use in scripts
DB_PASSWORD=$(ansible-vault view --vault-password-file ./scripts/ansible-vault-pass.sh credentials.vault | grep -A1 "db_password" | tail -1 | sed 's/.*: //')
```

### Rotating Vault Password
```bash
# Change vault password
pass edit ansible/vault  # Update password in pass
ansible-vault rekey --vault-password-file ./scripts/ansible-vault-pass.sh credentials.vault
```

## Integration with Development Workflow

The encrypted `credentials.vault` file is safe to:
- ✅ Commit to git repositories
- ✅ Share via encrypted channels
- ✅ Include in automated deployments
- ✅ Backup to cloud storage

The system integrates seamlessly with:
- Development environments (credentials accessible via vault)
- Personal workflow (single-user optimized)
- Future team collaboration (architecture supports multiple users)

## Best Practices

1. **Regular key rotation** - Update credentials periodically
2. **Backup verification** - Test GPG key backups regularly
3. **Personal security** - Regular GPG key backup verification
4. **Least privilege** - Only store necessary credentials
5. **Documentation** - Keep this guide updated with changes

---

**Security Note**: This system is only as secure as your GPG key. Ensure you follow proper GPG key management practices as outlined in `gpg_backup_strategies.md`.