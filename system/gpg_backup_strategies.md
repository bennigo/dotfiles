# GPG Backup Strategies

## ⚠️ Critical Security Warning

**NEVER store private GPG keys in git or any version control system!**

Private GPG keys are like master passwords and must be protected with the highest security measures. Once committed to git, they're extremely difficult to remove from history and could compromise all your encrypted data.

## Safe Backup Methods

### 1. Encrypted Offline Storage

Export your private key to an encrypted file and store on secure, offline media:

```bash
# Export private key (ASCII armored format)
gpg --export-secret-keys --armor your@email.com > gpg-private-key.asc

# Export public key for reference
gpg --export --armor your@email.com > gpg-public-key.asc

# Store files on:
# - Encrypted USB drives (multiple copies)
# - Secure cloud storage (encrypted before upload)
# - Encrypted external hard drives
```

### 2. Paper Backup with Paperkey

Generate a paper backup that can survive digital disasters:

```bash
# Install paperkey
sudo apt install paperkey

# Generate paper backup (much shorter than full key)
gpg --export-secret-key your@email.com | paperkey --output paper-key.txt

# Print paper-key.txt and store in:
# - Safe deposit box
# - Fire-proof safe
# - Multiple secure physical locations
```

**To restore from paper backup:**
```bash
# You need both the paper backup and your public key
paperkey --pubring ~/.gnupg/pubring.kbx --secrets paper-key.txt | gpg --import
```

### 3. Subkey Strategy (Advanced)

Use subkeys for daily operations while keeping master key offline:

```bash
# Create subkeys for different purposes
gpg --edit-key your@email.com
gpg> addkey
# Choose: (6) RSA encrypt only or (4) RSA sign only
# Or: (10) ECC encrypt only, (11) ECC sign only

# Export subkeys for daily use
gpg --export-secret-subkeys your@email.com > subkeys.gpg

# Store master key offline, use only subkeys daily
gpg --delete-secret-key your@email.com  # removes master key from keyring
gpg --import subkeys.gpg  # imports only subkeys
```

### 4. QR Code Backup

For tech-savvy users, encode key as QR codes:

```bash
# Install qrencode
sudo apt install qrencode

# Generate QR codes (split large keys into multiple codes)
gpg --export-secret-key --armor your@email.com | split -b 1000 - key-part-
for part in key-part-*; do
    qrencode -o "$part.png" < "$part"
done

# Print QR code images for physical backup
```

## What CAN Be Stored in Dotfiles

These files are safe to include in your dotfiles repository:

```bash
# Public GPG configuration
.gnupg/gpg.conf
.gnupg/gpg-agent.conf

# Public keys (not private!)
gpg --export --armor your@email.com > system/gpg-public-key.asc

# Scripts that use GPG
system/ansible-vault-pass.sh
```

## Backup Verification

Regularly test your backups:

```bash
# Test by restoring to a temporary keyring
mkdir /tmp/test-gpg
export GNUPGHOME=/tmp/test-gpg
gpg --import < your-backup-file.asc

# Verify key works
echo "test message" | gpg --encrypt -r your@email.com | gpg --decrypt

# Clean up
rm -rf /tmp/test-gpg
unset GNUPGHOME
```

## Recovery Scenarios

### Scenario 1: Lost laptop
- Restore from encrypted USB/cloud backup
- Revoke old subkeys if compromised
- Generate new subkeys for new device

### Scenario 2: Forgotten passphrase
- No recovery possible - this is by design
- Use paper backup to restore key with new passphrase
- This is why secure backup is critical

### Scenario 3: Corrupted keyring
- Restore from most recent backup
- Verify integrity with test decryption
- Update expiration dates if needed

## Best Practices

1. **Multiple backup locations** - Don't rely on single backup
2. **Regular testing** - Verify backups work every 6 months  
3. **Keep backups updated** - When you extend key expiration or add subkeys
4. **Document your system** - Note where backups are stored securely
5. **Use strong passphrases** - Protect your backups with good passwords
6. **Consider key expiration** - Set 2-5 year expiration, extend as needed

## Integration with Pass

Since you're using `pass` with GPG:

```bash
# Backup your password store too
tar czf pass-backup.tar.gz ~/.password-store/

# The .gpg-id file shows which GPG key encrypts your passwords
cat ~/.password-store/.gpg-id
```

Your `pass` passwords are only as secure as your GPG key backup strategy!