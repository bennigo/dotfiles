# GPG and Pass Tutorial

Complete guide to understanding and using GPG encryption with the `pass` password manager for secure credential storage.

## What is GPG?

GPG (GNU Privacy Guard) is a cryptographic software that provides encryption, digital signatures, and authentication. It uses public-key cryptography where you have:
- **Private key**: Kept secret, used for decryption and signing
- **Public key**: Can be shared, used for encryption and verification

## What is Pass?

Pass is a Unix password manager that stores passwords in GPG-encrypted files organized in a simple directory structure. Each password is encrypted with your GPG key.

## GPG Basics

### 1. Key Generation

```bash
# Interactive key generation
gpg --full-generate-key

# Recommended choices:
# Type: (9) ECC and ECC
# Curve: (1) Curve 25519 (modern, secure, fast)
# Expiration: 2y (2 years - forces regular key rotation)
# Name: Your real name
# Email: Your email address
# Passphrase: Strong password protecting your private key
```

**Key Types Explained:**
- **RSA**: Traditional, widely supported, larger keys (2048/4096 bits)
- **ECC/Ed25519**: Modern, smaller keys (256 bits), faster, equally secure
- **Expiration**: Forces periodic key renewal for security

### 2. Key Management

```bash
# List your keys
gpg --list-keys                    # Public keys
gpg --list-secret-keys            # Private keys
gpg --list-secret-keys --keyid-format LONG  # With key IDs

# Get key fingerprint/ID
gpg --list-secret-keys --keyid-format LONG
# Look for line like: sec   ed25519/0FA08B1A9096B394
# The part after / is your key ID: 0FA08B1A9096B394

# Export keys for backup
gpg --export-secret-keys --armor <KEY-ID> > secret-key.asc
gpg --export --armor <KEY-ID> > public-key.asc
gpg --export-ownertrust > trust.txt

# Import keys from backup
gpg --import secret-key.asc
gpg --import public-key.asc
gpg --import-ownertrust trust.txt
```

### 3. GPG Configuration

**GPG Agent Config** (`~/.gnupg/gpg-agent.conf`):
```bash
# Cache passphrase for 3 hours (10800 seconds)
default-cache-ttl 10800
max-cache-ttl 10800

# SSH key caching
default-cache-ttl-ssh 10800
max-cache-ttl-ssh 10800

# Pinentry program (for password prompts)
pinentry-program /usr/bin/pinentry-curses
```

**Reload configuration:**
```bash
gpgconf --reload gpg-agent
gpgconf --kill gpg-agent    # Force restart if needed
```

### 4. Basic GPG Operations

```bash
# Encrypt a file
gpg --encrypt --recipient <KEY-ID> file.txt

# Decrypt a file
gpg --decrypt file.txt.gpg

# Test encryption/decryption
echo "test message" | gpg --encrypt -r <KEY-ID> | gpg --decrypt

# Change key passphrase
gpg --passwd <KEY-ID>
```

## Pass Usage

### 1. Initialization

```bash
# Initialize pass with your GPG key
pass init <YOUR-GPG-KEY-ID>

# Example:
pass init 0FA08B1A9096B394
```

### 2. Basic Operations

```bash
# Generate a password
pass generate website/login 32          # 32 character random password
pass generate -n website/login 20       # No symbols, 20 characters
pass generate -c website/login 25       # Copy to clipboard, 25 chars

# Store a password manually
pass insert website/login               # Enter password when prompted
pass insert -m website/login            # Multiline entry (notes, etc.)

# Retrieve passwords
pass show website/login                 # Show password
pass show -c website/login              # Copy to clipboard
pass ls                                 # List all passwords

# Edit entries
pass edit website/login                 # Open in editor

# Remove entries
pass rm website/login                   # Delete password
pass rm -r website                     # Delete folder and contents
```

### 3. Organization

```bash
# Pass uses hierarchical structure
pass ls
Password Store
├── personal/
│   ├── email/gmail
│   └── banking/account1
├── work/
│   ├── servers/production
│   └── services/api-key
└── ansible/
    └── vault

# Create folders automatically
pass generate work/servers/new-server 32
```

### 4. Git Integration

```bash
# Initialize git repo in password store
pass git init

# Automatic commits on changes
pass generate website/new 32    # Automatically commits

# Manual git operations
pass git log                    # View history
pass git push                   # Push to remote (if configured)
```

## Integration with Ansible Vault

### 1. Storing Vault Password

```bash
# Generate vault password
pass generate ansible/vault 32

# Verify it works
pass show ansible/vault
```

### 2. Automatic Script

**Script**: `scripts/ansible-vault-pass.sh`
```bash
#!/bin/bash
pass show ansible/vault
```

**Usage:**
```bash
# Use script for vault operations
ansible-vault view --vault-password-file ./scripts/ansible-vault-pass.sh credentials.vault
ansible-vault edit --vault-password-file ./scripts/ansible-vault-pass.sh credentials.vault

# Or set environment variable
export ANSIBLE_VAULT_PASSWORD_FILE="$HOME/.dotfiles/system/scripts/ansible-vault-pass.sh"
ansible-vault view credentials.vault  # No need to specify password file
```

## Troubleshooting

### Common Issues

**1. "No such file or directory" error:**
```bash
# Check if GPG is working
gpg --list-keys

# Check if pass is initialized
pass ls
```

**2. "Decryption failed" error:**
```bash
# Wrong passphrase or corrupted key
gpg --passwd <KEY-ID>  # Change passphrase to test

# Restart GPG agent
gpgconf --kill gpg-agent
```

**3. "Inappropriate ioctl for device":**
```bash
# Pinentry issue - check agent config
cat ~/.gnupg/gpg-agent.conf

# Or use different pinentry
echo "pinentry-program /usr/bin/pinentry-tty" >> ~/.gnupg/gpg-agent.conf
gpgconf --reload gpg-agent
```

**4. Pass entries not decrypting:**
```bash
# Check pass was initialized with correct key
cat ~/.password-store/.gpg-id

# Should match your key ID
gpg --list-secret-keys --keyid-format LONG
```

### Recovery Steps

**If completely broken:**
1. Backup existing data: `cp -r ~/.gnupg ~/.gnupg.broken`
2. Check if keys exist: `gpg --list-secret-keys`
3. If no keys, restore from backup or generate new
4. Reinitialize pass: `pass init <KEY-ID>`
5. Restore passwords from backup files

## Security Best Practices

### 1. Strong Passphrases
- **Length**: 4+ random words or 16+ mixed characters
- **Uniqueness**: Different from other passwords
- **Memory aids**: Use memorable phrases you can type reliably

### 2. Key Security
- **Backup**: Export keys to secure location
- **Expiration**: Set 2-3 year expiration, renew regularly
- **Revocation**: Keep revocation certificate safe
- **Sharing**: Never share private keys

### 3. Pass Security
- **Permissions**: Keep `~/.password-store` secure (700)
- **Backup**: Regular encrypted backups
- **Git**: Use private repos if syncing
- **Cleanup**: Remove old/unused entries

### 4. System Security
- **Screen lock**: Auto-lock when idle
- **Disk encryption**: Full disk encryption enabled
- **Updates**: Keep GPG/pass updated
- **Monitoring**: Watch for unauthorized access

## Quick Reference

```bash
# Essential commands
gpg --list-secret-keys --keyid-format LONG
pass init <KEY-ID>
pass generate service/account 32
pass show service/account
pass ls

# Configuration files
~/.gnupg/gpg-agent.conf        # GPG agent settings
~/.password-store/             # Pass data directory
~/.password-store/.gpg-id      # Pass GPG key ID

# Troubleshooting
gpgconf --kill gpg-agent       # Restart agent
gpg --passwd <KEY-ID>          # Change passphrase
pass init <KEY-ID>             # Reinitialize pass
```

Remember: **GPG and pass form the foundation of your credential security!**