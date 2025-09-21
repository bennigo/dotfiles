# Emergency Recovery Guide

This document outlines recovery procedures when you're locked out of the credentials system due to lost GPG keys, forgotten passphrases, or other emergencies.

## Recovery Scenarios

### 1. Lost GPG Key Passphrase

**Symptoms:**
- Can't decrypt pass entries
- GPG operations fail with "decryption failed"
- `pass show` commands fail

**Recovery Steps:**
1. **Try passphrase variants** - Check if you might have mistyped
2. **Check GPG agent cache** - Restart GPG agent if needed:
   ```bash
   gpgconf --kill gpg-agent
   gpgconf --launch gpg-agent
   ```
3. **If completely lost** - Generate new GPG key (see below)

### 2. Lost GPG Key Completely

**Symptoms:**
- No GPG keys in keyring
- Fresh system install
- Hardware failure with no backup

**Recovery Steps:**
1. **Generate new GPG key:**
   ```bash
   gpg --full-generate-key
   # Choose: (9) ECC and ECC, then (1) Curve 25519
   # Set 2-year expiration
   # Use strong passphrase
   ```

2. **Reinitialize pass:**
   ```bash
   rm -rf ~/.password-store
   pass init <NEW-GPG-KEY-ID>
   ```

3. **Restore from backup files:**
   - Copy credentials from `~/.dotfiles/system/.credentials_and_logins/`
   - Run setup script: `./scripts/setup_vault.sh`
   - Migrate credentials: `python3 scripts/copy_credentials.py`

### 3. Lost Ansible Vault Password

**Symptoms:**
- Can't decrypt `credentials.vault`
- "incorrect vault password" errors
- Pass works but vault access fails

**Recovery Options:**

**Option A: If password is in pass store:**
```bash
pass show ansible/vault
ansible-vault view credentials.vault
```

**Option B: If pass is broken, try manual password:**
```bash
ansible-vault view credentials.vault
# Enter password manually when prompted
```

**Option C: Complete vault rebuild:**
1. Restore from backup: `python3 scripts/copy_credentials.py`
2. Create new vault: `ansible-vault encrypt credentials_populated.yml`
3. Replace old vault: `mv credentials_populated.yml credentials.vault`

### 4. Complete System Loss

**When everything is lost:**

1. **Restore SSH keys first:**
   ```bash
   cp ~/.dotfiles/system/.credentials_and_logins/ssh_keys/* ~/.ssh/
   chmod 700 ~/.ssh
   chmod 600 ~/.ssh/id_* ~/.ssh/config ~/.ssh/authorized_keys
   chmod 644 ~/.ssh/*.pub ~/.ssh/known_hosts
   ```

2. **Rebuild GPG infrastructure:**
   ```bash
   gpg --full-generate-key
   pass init <GPG-KEY-ID>
   ```

3. **Restore credentials vault:**
   ```bash
   cd ~/.dotfiles/system
   ./scripts/setup_vault.sh
   python3 scripts/copy_credentials.py
   ansible-vault encrypt --vault-password-file ./scripts/ansible-vault-pass.sh credentials_populated.yml
   mv credentials_populated.yml credentials.vault
   ```

## Prevention Strategies

### 1. Multiple Backups
- **Physical backup disk** with credentials
- **Printed QR codes** for critical passwords
- **Trusted device** with access maintained

### 2. GPG Key Backup
```bash
# Export secret key (store securely!)
gpg --export-secret-keys --armor <KEY-ID> > private-key-backup.asc

# Export public key
gpg --export --armor <KEY-ID> > public-key-backup.asc

# Export ownertrust
gpg --export-ownertrust > ownertrust-backup.txt
```

### 3. Test Recovery Regularly
- Monthly: Test `pass show` commands
- Quarterly: Test full vault decryption
- Yearly: Practice complete system rebuild

### 4. Document Your Setup
- Write down GPG key ID
- Note vault password location
- Keep copy of this recovery guide offline

## Emergency Contacts

**If completely locked out:**
1. Check backup disk for credential files
2. Review physical password records
3. Use SSH keys for server access to retrieve backups
4. Contact system administrator if in corporate environment

## Quick Reference Commands

```bash
# Check GPG keys
gpg --list-secret-keys --keyid-format LONG

# Check pass store
pass ls

# Test vault access
ansible-vault view credentials.vault

# Force GPG agent restart
gpgconf --kill gpg-agent && gpgconf --launch gpg-agent

# Backup current state
cp -r ~/.gnupg ~/.gnupg.backup
cp -r ~/.password-store ~/.password-store.backup
cp credentials.vault credentials.vault.backup

# Check file permissions
ls -la ~/.ssh/
ls -la ~/.gnupg/
```

## Recovery Checklist

- [ ] SSH keys restored and accessible
- [ ] GPG key generated with strong passphrase
- [ ] Pass initialized and working
- [ ] Credentials vault accessible
- [ ] Backup strategy implemented
- [ ] Recovery procedures tested

Remember: **The backup files in `.credentials_and_logins/` are your ultimate fallback!**