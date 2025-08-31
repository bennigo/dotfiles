# Adding Credentials to Encrypted Vault

This document describes the complete procedure for safely adding, editing, and committing credential changes to your encrypted vault.

## Overview

The procedure follows this secure workflow:
```
Decrypt → Edit/Add → Validate → Encrypt → Commit → Cleanup
```

Every step includes safety checks, backups, and validation to prevent data loss or corruption.

## Quick Start

### Interactive Method (Recommended)
```bash
cd ~/.dotfiles/system/
./scripts/add-credentials.sh
```

This script provides a guided interface for all credential operations.

### Manual Method
```bash
cd ~/.dotfiles/system/

# 1. Edit vault directly (opens in your editor)
ansible-vault edit --vault-password-file ./scripts/ansible-vault-pass.sh credentials.vault

# 2. Commit changes
./scripts/commit-credentials.sh "Add new API credentials"
```

## Detailed Procedures

### Method 1: Interactive Script (Recommended)

The `add-credentials.sh` script provides a safe, guided interface:

#### Features
- ✅ **Automatic backups** before any changes
- ✅ **YAML validation** to prevent corruption
- ✅ **Change preview** before encryption
- ✅ **Safe cancellation** with backup restoration
- ✅ **Git integration** with proper commit messages

#### Step-by-Step Usage

1. **Start the script**:
   ```bash
   cd ~/.dotfiles/system/
   ./scripts/add-credentials.sh
   ```

2. **Choose your action**:
   - `1) Add new credential` - Guided credential addition
   - `2) Edit vault manually` - Opens editor for manual changes
   - `3) View current structure` - Shows vault organization
   - `4) Finish and encrypt` - Complete the process
   - `5) Cancel` - Abort and restore backup

3. **Adding a new credential**:
   ```
   Enter credential name: new_api_key
   
   Available sections:
   1) credentials (default)
   2) ssh_keys  
   3) other (specify)
   Select section: 1
   
   Choose input method:
   1) Type value directly
   2) Read from file
   3) Multi-line input
   Select method: 1
   
   Enter credential value: [hidden input]
   ```

4. **Review and commit**:
   - Script shows changes made
   - Confirms encryption
   - Offers to commit to git
   - Cleans up temporary files

#### Input Methods

**Direct Input** (passwords, API keys):
```
Select method: 1
Enter credential value (hidden): your-secret-key
```

**From File** (certificates, config files):
```
Select method: 2
Enter file path: /path/to/certificate.pem
```

**Multi-line** (SSH keys, JSON configs):
```
Select method: 3
Enter multi-line value (press Ctrl+D when done):
-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEA...
-----END RSA PRIVATE KEY-----
^D
```

### Method 2: Direct Vault Editing

For quick edits by experienced users:

```bash
# Edit vault (opens in your default editor)
ansible-vault edit --vault-password-file ./scripts/ansible-vault-pass.sh credentials.vault

# Your editor opens with decrypted YAML:
# credentials:
#   existing_key: "existing_value"
#   new_key: "new_value"        # Add this line
# ssh_keys:
#   existing_key: |
#     -----BEGIN SSH KEY-----
#     ...

# Save and exit - file automatically re-encrypts
```

**Important**: Use correct YAML syntax. Invalid YAML will cause encryption to fail.

### Method 3: Programmatic Addition

For automation or bulk additions:

```bash
# Decrypt to temp file
ansible-vault decrypt --vault-password-file ./scripts/ansible-vault-pass.sh --output temp.yml credentials.vault

# Modify with script/program (e.g., Python, jq, yq)
python3 -c "
import yaml
with open('temp.yml', 'r') as f: data = yaml.safe_load(f)
data['credentials']['new_key'] = 'new_value'
with open('temp.yml', 'w') as f: yaml.dump(data, f)
"

# Re-encrypt
ansible-vault encrypt --vault-password-file ./scripts/ansible-vault-pass.sh --output credentials.vault temp.yml

# Clean up
rm temp.yml

# Commit changes
./scripts/commit-credentials.sh "Automated credential update"
```

## YAML Structure

Your vault follows this structure:

```yaml
credentials:
  # Simple text credentials
  api_key: "your-api-key"
  database_password: "secure-password"
  
  # Multi-line credentials (use | for literal blocks)
  certificate: |
    -----BEGIN CERTIFICATE-----
    MIIDXTCCAkWgAwIBAgIJAKoK/heBjcOuMA0GCSqGSIb3...
    -----END CERTIFICATE-----
  
  # JSON stored as strings
  oauth_config: '{"client_id":"123","client_secret":"abc"}'

ssh_keys:
  # SSH private keys
  id_rsa: |
    -----BEGIN RSA PRIVATE KEY-----
    MIIEpAIBAAKCAQEA...
    -----END RSA PRIVATE KEY-----
  
  # SSH public keys
  id_rsa_pub: "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQ..."
  
  # SSH config files
  config: |
    Host myserver
        HostName server.example.com
        User myuser
        IdentityFile ~/.ssh/id_rsa

# Custom sections
database_connections:
  production: "postgresql://user:pass@prod.example.com:5432/db"
  staging: "postgresql://user:pass@staging.example.com:5432/db"
```

## Commit Procedures

### Using commit-credentials.sh

```bash
# Simple commit with default message
./scripts/commit-credentials.sh

# Commit with custom message
./scripts/commit-credentials.sh "Add production database credentials"

# Show changes before committing
./scripts/commit-credentials.sh --show-diff "Update API keys"
```

### Manual Git Commit

```bash
# Check status
git status

# Add vault file
git add credentials.vault

# Commit with descriptive message
git commit -m "Update credentials vault

Added new API keys for external services

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

## Security Best Practices

### During Editing

1. **Always use the scripts** - they include safety checks
2. **Work in secure environment** - no screen sharing, secure terminal
3. **Validate YAML syntax** - invalid YAML can cause data loss
4. **Use temp files carefully** - clean up immediately after use

### Credential Values

1. **No trailing spaces** - can cause issues with some services
2. **Escape special characters** in YAML strings:
   ```yaml
   password_with_quotes: 'password"with"quotes'
   password_with_single: "password'with'single"
   ```
3. **Use appropriate YAML formatting**:
   - Simple strings: `key: "value"`
   - Multi-line: `key: |` (literal) or `key: >` (folded)
   - Special characters: Use quotes to prevent YAML interpretation

### Git Workflow

1. **Meaningful commit messages** - describe what credentials were added/changed
2. **Regular commits** - don't accumulate too many changes
3. **Review changes** - use `--show-diff` option when possible
4. **Branch workflow** - consider using feature branches for major credential updates

## Troubleshooting

### Common Issues

**"Invalid YAML syntax" error:**
```bash
# Check syntax manually
python3 -c "import yaml; yaml.safe_load(open('temp_file.yml'))"

# Common issues:
# - Missing quotes around values with special characters
# - Incorrect indentation (use spaces, not tabs)
# - Unescaped quotes in strings
```

**"Vault password retrieval failed":**
```bash
# Test password script
./scripts/ansible-vault-pass.sh

# Check pass setup
pass show ansible/vault

# Verify GPG key
gpg --list-secret-keys
```

**"File corruption" or encryption fails:**
```bash
# Restore from backup (created by add-credentials.sh)
ls credentials_backup_*.yml
cp credentials_backup_TIMESTAMP.yml credentials.vault
```

**Git commit issues:**
```bash
# Check git status
git status

# Reset staged changes if needed
git reset HEAD credentials.vault

# Check for merge conflicts
git diff --check
```

### Recovery Procedures

**If vault becomes corrupted:**
1. Find latest backup: `ls -la credentials_backup_*.yml`
2. Restore backup: `cp credentials_backup_LATEST.yml credentials.vault`
3. Check git history: `git log --oneline -- credentials.vault`
4. Restore from git: `git checkout HEAD~1 -- credentials.vault`

**If password is lost:**
1. Check pass store: `pass show ansible/vault`
2. Regenerate vault with new password: `ansible-vault rekey credentials.vault`
3. Update pass: `pass edit ansible/vault`

**If temp files left behind:**
```bash
# Clean up any temp files
rm -f credentials_temp.yml credentials_original.yml temp.yml
```

## Advanced Usage

### Bulk Operations

Add multiple credentials from a JSON file:
```python
#!/usr/bin/env python3
import yaml
import json

# Load existing vault
with open('temp_decrypted.yml', 'r') as f:
    vault_data = yaml.safe_load(f)

# Load new credentials from JSON
with open('new_credentials.json', 'r') as f:
    new_creds = json.load(f)

# Add to vault
for key, value in new_creds.items():
    vault_data['credentials'][key] = value

# Save back
with open('temp_decrypted.yml', 'w') as f:
    yaml.dump(vault_data, f, default_flow_style=False)
```

### Environment-Specific Vaults

Manage separate vaults for different environments:
```bash
# Development vault
ansible-vault edit --vault-password-file ./scripts/ansible-vault-pass.sh credentials-dev.vault

# Production vault  
ansible-vault edit --vault-password-file ./scripts/ansible-vault-pass.sh credentials-prod.vault

# Staging vault
ansible-vault edit --vault-password-file ./scripts/ansible-vault-pass.sh credentials-staging.vault
```

### Integration with CI/CD

Access credentials in automated workflows:
```bash
#!/bin/bash
# Extract specific credential for use in deployment
DB_PASSWORD=$(ansible-vault view --vault-password-file ./scripts/ansible-vault-pass.sh credentials.vault | grep -A1 "database_password" | tail -1 | sed 's/.*: "\(.*\)"/\1/')
export DB_PASSWORD
```

## Summary

The credential management system provides multiple secure methods for adding and updating encrypted credentials:

1. **Interactive script** (`add-credentials.sh`) - Safest, most user-friendly
2. **Direct editing** (`ansible-vault edit`) - Quick for experienced users  
3. **Programmatic** - For automation and bulk operations

All methods include safety features like backups, validation, and proper git integration. The encrypted vault files can be safely stored in git while maintaining security through GPG-protected password management.