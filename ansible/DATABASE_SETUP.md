# Database Setup - PostgreSQL with Secure Credential Management

This document covers the complete PostgreSQL setup integrated into the Ansible bootstrap system, including secure credential management using `pass`.

## Overview

The database role provides:
- **PostgreSQL 18** installation from official repository
- **Development user setup** with appropriate privileges
- **Secure credential management** using GPG-encrypted `pass` storage
- **Version control safe configuration** with no hardcoded passwords
- **Cross-system deployment** via Ansible automation

## Quick Start - Fresh Installation

### 1. Bootstrap with Database
```bash
cd ~/.dotfiles/ansible
ansible-playbook bootstrap.yml --extra-vars "profile=work_laptop"
# OR for development-only
ansible-playbook bootstrap.yml --extra-vars "profile=development"
```

### 2. Clone Password Store (Infrastructure Credentials)
```bash
git clone git@github.com:bennigo/bgo-pstore.git ~/.password-store
```

### 3. Generate Database Credentials
```bash
update-pgpass  # Creates ~/.pgpass from pass credentials
```

### 4. Ready to Use!
```bash
nvim           # Database UI works immediately
psql bgo       # Connect to default database
createdb test  # Create new databases
```

## Profiles That Include Database

The database role is included in these bootstrap profiles:
- **development**: Core development setup with database
- **desktop**: Full desktop environment with database
- **full**: Complete installation with all components
- **work_laptop**: Professional workstation setup

**Not included:**
- **minimal**: Lightweight setup without database

## Database Role Architecture

### Files Structure
```
ansible/roles/database/
├── tasks/main.yml           # Installation and configuration
├── handlers/main.yml        # Service management
├── defaults/main.yml        # Configuration variables
└── files/
    ├── update-pgpass        # Credential management script
    └── nvim-db             # Alternative environment wrapper
```

### What Gets Installed

**PostgreSQL Components:**
- PostgreSQL server (latest from official repository)
- PostgreSQL contrib modules and extensions
- Client libraries and development headers
- Python psycopg2 for Ansible modules

**User Configuration:**
- PostgreSQL user `bgo` with CREATEDB and CREATEROLE privileges
- Default database `bgo` owned by development user
- Both peer authentication (Unix socket) and password authentication (TCP)

**Service Configuration:**
- Auto-start on system boot
- Optimized for development workloads
- Logging configured for debugging

## Credential Management System

### Security Architecture

**Storage:**
- Passwords encrypted in `pass` using GPG key `0FA08B1A9096B394`
- Private repository at `git@github.com:bennigo/bgo-pstore.git`
- No hardcoded passwords in version control

**Authentication:**
- `.pgpass` file for native PostgreSQL authentication
- Works with all PostgreSQL tools (psql, pg_dump, Neovim db_ui)
- Environment variables as fallback option

### Password Store Structure
```
~/.password-store/
├── ansible/vault.gpg        # Ansible vault password
├── database/
│   ├── local_dev_password.gpg    # Local PostgreSQL password
│   └── vedur_password.gpg        # Vedur database credentials
└── .gpg-id                  # GPG key identifier
```

### Neovim Database UI Configuration

**Version Control Safe connections.json:**
```json
[
  {
    "url": "postgresql://bgo@localhost:5432/bgo",
    "name": "local_db"
  },
  {
    "url": "postgresql://bgo@pgread.vedur.is:5432/gas",
    "name": "gas_read"
  }
]
```

No passwords stored in configuration files - all handled via `.pgpass`.

## Installation Details

### Repository Setup
- Uses PostgreSQL official APT repository for latest versions
- Modern GPG key management (no deprecated `apt-key`)
- Automatic version detection (currently installs PostgreSQL 18)

### Authentication Configuration
- **Peer authentication**: For Unix socket connections (development workflow)
- **Password authentication**: For TCP connections (GUI tools, remote access)
- **pg_hba.conf** configured for both methods

### Development Workflow
```bash
# Peer authentication (no password)
psql bgo
createdb myproject
psql myproject

# TCP authentication (uses .pgpass)
psql -h localhost -U bgo -d bgo
psql -h pgread.vedur.is -U bgo -d gas
```

## Scripts and Tools

### update-pgpass
**Location:** `~/.local/bin/update-pgpass`
**Purpose:** Generate `.pgpass` file from `pass` credentials

```bash
update-pgpass  # Regenerates ~/.pgpass from pass store
```

**Features:**
- Checks for password existence before adding entries
- Proper file permissions (600) automatically set
- Status feedback for successful/failed operations

### nvim-db (Optional)
**Location:** `~/.local/bin/nvim-db`
**Purpose:** Alternative approach using environment variables

```bash
nvim-db        # Launches nvim with database env vars loaded
```

## Troubleshooting

### Password Authentication Issues

**Problem:** `psql: no password supplied`
**Solution:**
```bash
update-pgpass    # Regenerate .pgpass
chmod 600 ~/.pgpass  # Fix permissions
```

**Problem:** Neovim db_ui asks for password
**Solution:** Check connection strings use hostnames that match `.pgpass` entries

### Permission Issues

**Problem:** `FATAL: peer authentication failed`
**Solution:** Use TCP connection or verify Unix socket permissions
```bash
# Use TCP (uses .pgpass)
psql -h localhost -U bgo -d bgo

# Or check socket auth
sudo -u bgo psql -d bgo
```

### Version Issues

**Problem:** Wrong PostgreSQL version installed
**Solution:** Role auto-detects version, but you can override:
```yaml
postgresql_version: "16"  # In group_vars/all.yml
```

## Security Best Practices

### GPG Key Management
- Keep GPG private key backed up securely
- Use strong GPG key passphrase
- Regular key expiration and renewal

### Password Store Security
- Regular commits to private repository for backup
- Keep personal passwords in separate, local-only directories
- Use `.gitignore` to exclude sensitive password categories

### Database Security
- Local development setup only (localhost binding)
- Development user privileges appropriate for non-production
- Regular password rotation for production databases

## Fresh System Recovery

### Complete Environment Restoration
```bash
# 1. Clone dotfiles
git clone git@github.com:bennigo/.dotfiles.git ~/.dotfiles

# 2. Clone password store
git clone git@github.com:bennigo/bgo-pstore.git ~/.password-store

# 3. Bootstrap system
cd ~/.dotfiles/ansible
ansible-playbook bootstrap.yml --extra-vars "profile=work_laptop"

# 4. Setup database credentials
update-pgpass

# 5. Verify setup
psql bgo -c "SELECT version();"
nvim  # Test database UI
```

### Partial Database-Only Setup
```bash
# Install just PostgreSQL
ansible-playbook bootstrap.yml --tags "database"

# Or reinstall credentials only
ansible-playbook bootstrap.yml --tags "credentials,scripts"
```

## Integration with Development Workflow

### Daily Usage
- No password prompts needed for database connections
- Neovim db_ui works seamlessly with all configured databases
- Command line tools automatically authenticate

### Adding New Databases
1. Add credentials to password store:
   ```bash
   pass insert database/new_service_password
   ```

2. Update `.pgpass`:
   ```bash
   update-pgpass
   ```

3. Add connection to `neovim/.config/nvim/db_ui/connections.json`

4. Commit changes:
   ```bash
   cd ~/.password-store
   git add . && git commit -m "Add new database credentials"
   git push
   ```

## Maintenance

### Password Updates
```bash
pass edit database/vedur_password
update-pgpass  # Regenerate .pgpass
cd ~/.password-store && git add . && git commit -m "Update credentials" && git push
```

### System Updates
```bash
# Update PostgreSQL
sudo apt update && sudo apt upgrade postgresql

# Re-run database role if needed
ansible-playbook bootstrap.yml --tags "database"
```

---

**Created:** 2025-09-29
**Context:** Part of dotfiles automation system
**Dependencies:** GPG, pass, Ansible, PostgreSQL official repository