# Credentials Management Scripts

This directory contains scripts for setting up and managing encrypted credentials using Ansible Vault with `pass` integration.

## Quick Reference

- `setup_vault.sh` - Initial setup (run once)
- `add-credentials.sh` - Interactive credential management (recommended)
- `commit-credentials.sh` - Git workflow for vault changes
- `ansible-vault-pass.sh` - Password retrieval from pass
- `copy_credentials.py` - Migration from existing credentials

## Scripts Overview

### `setup_vault.sh`
**Purpose**: Main setup script that initializes the entire credentials management system.

**What it does**:
- Verifies prerequisites (pass, ansible, GPG)
- Creates vault password in `pass` store
- Generates credentials template YAML file
- Sets up environment variables for easy access

**Usage**:
```bash
./setup_vault.sh
```

**Prerequisites**:
- GPG key generated and configured
- `pass` initialized with GPG key
- `ansible` package installed

---

### `ansible-vault-pass.sh`
**Purpose**: Password retrieval script that securely fetches the vault password from `pass`.

**What it does**:
- Retrieves vault password from `pass` store entry `ansible/vault`
- Provides password to ansible-vault commands automatically
- Handles error cases (pass not initialized, password not found)

**Usage**:
```bash
# Used automatically by ansible-vault commands
ansible-vault edit --vault-password-file ./scripts/ansible-vault-pass.sh credentials.vault

# Or set as environment variable
export ANSIBLE_VAULT_PASSWORD_FILE="./scripts/ansible-vault-pass.sh"
ansible-vault edit credentials.vault
```

**Security Features**:
- No plaintext passwords stored in files
- Password retrieved from GPG-encrypted `pass` store
- Automatic error handling and user guidance

---

### `copy_credentials.py`
**Purpose**: Migration script that copies existing credentials into YAML structure for encryption.

**What it does**:
- Reads files from `.credentials_and_logins/` directory
- Handles text files, JSON files, and binary files (SSH keys)
- Creates structured YAML suitable for ansible-vault
- Provides detailed progress feedback

**Usage**:
```bash
python3 scripts/copy_credentials.py
```

**File Mappings**:
```
.credentials_and_logins/afreksnefnd_email.txt → credentials.afreksnefnd_email
.credentials_and_logins/azores.login → credentials.azores_login
.credentials_and_logins/openai_nvim_key.txt → credentials.openai_nvim_key
.credentials_and_logins/ssh_keys/* → ssh_keys.*
# ... and more
```

**Features**:
- Smart content detection (text vs binary)
- Base64 encoding for binary files
- Error handling and progress reporting
- Validation of template file existence

---

### `add-credentials.sh`
**Purpose**: Interactive credential management with full decrypt → edit → encrypt → commit workflow.

**What it does**:
- Creates automatic backups before any changes
- Provides guided interface for adding credentials
- Validates YAML syntax to prevent corruption
- Shows change previews before encryption
- Integrates with git for proper commit workflow
- Handles cancellation with backup restoration

**Usage**:
```bash
./add-credentials.sh
```

**Features**:
- Multiple input methods (direct, file, multi-line)
- Section organization (credentials, ssh_keys, custom)
- Safe cancellation and error recovery
- Change validation and preview
- Automated git integration

---

### `commit-credentials.sh`
**Purpose**: Git workflow script for committing credential vault changes.

**What it does**:
- Checks git status and vault file changes
- Provides proper commit messages with timestamps
- Shows file change statistics (encrypted, so no content diff)
- Handles both tracked and untracked vault files
- Follows conventional commit message format

**Usage**:
```bash
# Simple commit with default message
./commit-credentials.sh

# Custom commit message
./commit-credentials.sh "Add production API keys"

# Show changes before committing
./commit-credentials.sh --show-diff "Update database credentials"
```

**Features**:
- Automatic change detection
- Customizable commit messages
- Git integration with proper formatting
- File status validation
- Interactive confirmation

## Complete Workflow

### Initial Setup
```bash
# 1. Run main setup (creates template, sets up pass integration)
./scripts/setup_vault.sh

# 2. Copy existing credentials to YAML structure  
python3 scripts/copy_credentials.py

# 3. Encrypt the populated credentials
ansible-vault encrypt --vault-password-file ./scripts/ansible-vault-pass.sh credentials_populated.yml

# 4. Rename to final vault file
mv credentials_populated.yml credentials.vault
```

### Daily Usage

**Recommended: Interactive Management**
```bash
# Guided credential addition/editing (includes commit workflow)
./scripts/add-credentials.sh
```

**Quick Manual Edit**
```bash
# Direct vault editing
ansible-vault edit --vault-password-file ./scripts/ansible-vault-pass.sh credentials.vault

# Commit changes after editing
./scripts/commit-credentials.sh "Updated API credentials"
```

**Viewing Credentials**
```bash
# View entire vault (password retrieved automatically)
ansible-vault view --vault-password-file ./scripts/ansible-vault-pass.sh credentials.vault

# Or use environment variable (if set by setup script)
export ANSIBLE_VAULT_PASSWORD_FILE="./scripts/ansible-vault-pass.sh"
ansible-vault view credentials.vault
```

## Security Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   GPG Private   │───▶│  Pass Store     │───▶│ Ansible Vault   │
│      Key        │    │ ansible/vault   │    │ Password Script │
└─────────────────┘    └─────────────────┘    └─────────────────┘
        │                       │                       │
        ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│ GPG Passphrase  │    │ Vault Password  │    │ AES256 Encrypted│
│ (User Memory)   │    │ (GPG Encrypted) │    │ Credentials     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

**Security Layers**:
1. **GPG Layer**: Private key protected by passphrase
2. **Pass Layer**: Vault password encrypted with GPG key  
3. **Ansible Layer**: Credentials encrypted with AES256 using vault password

## Troubleshooting

### Common Issues

**"Error: pass is not initialized"**
```bash
# Fix: Initialize pass with your GPG key
pass init <YOUR-GPG-KEY-ID>
```

**"Permission denied" on script execution**
```bash
# Fix: Make scripts executable
chmod +x scripts/*.sh scripts/*.py
```

**"Password entry not found"**
```bash
# Fix: Create vault password manually
pass insert ansible/vault
```

**"GPG decryption failed"**
```bash
# Fix: Check GPG key and agent
gpg --list-secret-keys
gpg-agent --daemon
```

### Script Debugging

**Test password retrieval**:
```bash
./scripts/ansible-vault-pass.sh
# Should output your vault password
```

**Test template creation**:
```bash
./scripts/setup_vault.sh
ls -la credentials_template.yml
```

**Test credential copying**:
```bash
python3 scripts/copy_credentials.py
less credentials_populated.yml
```

## Maintenance

### Regular Tasks
- **Update credentials**: Use `ansible-vault edit` to modify entries
- **Rotate vault password**: Use `pass edit ansible/vault` + `ansible-vault rekey`
- **Backup verification**: Test GPG key backups periodically

### Adding New Credentials
1. Edit vault: `ansible-vault edit credentials.vault`
2. Add new entries in appropriate section
3. Save (file remains encrypted automatically)

### Security Auditing
- Review access logs for vault files
- Verify GPG key expiration dates
- Check `pass` store integrity: `pass git log`

## Integration Points

These scripts integrate with:
- **Development environment**: Credentials accessible via ansible-vault
- **Git workflow**: Encrypted vault safe to commit  
- **Backup systems**: Works with existing GPG/pass backup strategies
- **Team collaboration**: Shared vault files, individual GPG keys

For complete documentation, see `../credentials.md`.