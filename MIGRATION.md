# Machine Migration Guide

How to move your dotfiles setup from one machine to another. The old machine stays
intact until you've verified the new one works.

## Before you start

Collect these from the old machine:

### 1. GPG private key

```bash
gpg --export-secret-keys --armor 0FA08B1A9096B394 > /tmp/git-crypt-key.asc
```

Transfer via USB stick. **Delete the export after import on the new machine.**

### 2. Password store

```bash
# Option A: rsync to new machine
rsync -av ~/.password-store/ newmachine:~/.password-store/

# Option B: clone from remote (if you have one)
git clone git@github.com:bennigo/pwstore.git ~/.password-store
```

### 3. SSH keys (if not in ansible-vault)

```bash
rsync -av ~/.ssh/ newmachine:~/.ssh/
chmod 700 ~/.ssh && chmod 600 ~/.ssh/id_*
```

If SSH keys are stored in `credentials.vault`, the credentials role will extract them —
skip this step.

### 4. Ansible vault password

This is whatever `system/scripts/ansible-vault-pass.sh` reads. Usually stored in `pass`:

```bash
pass show ansible/vault-password  # verify you can read it
```

If pass is transferred (step 2), this comes for free.

## On the new machine

### 1. Minimal prerequisites

```bash
sudo apt update
sudo apt install -y git stow ansible python3-apt git-crypt gnupg openssh-server
```

### 2. Import GPG key and clone dotfiles

```bash
gpg --import /path/to/git-crypt-key.asc
git clone https://github.com/bennigo/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
git submodule update --init --recursive
cd claude-private && git-crypt unlock && cd ~
```

### 3. Bootstrap

Choose a profile that matches the new machine's role:

```bash
cd ~/.dotfiles/ansible

# Full work laptop (most common):
ansible-playbook bootstrap.yml --extra-vars "profile=work_laptop" --ask-become-pass

# Headless dev box:
ansible-playbook bootstrap.yml --extra-vars "profile=development" --ask-become-pass
```

See [`PLAYBOOK_GUIDE.md`](PLAYBOOK_GUIDE.md) for all profiles and the decision tree.

### 4. Reboot and verify

```bash
sudo reboot
# After reboot:
echo $XDG_SESSION_TYPE   # wayland (if desktop profile)
swaymsg -t get_version   # sway responds (if desktop profile)
pass ls                  # password store works
psql bgo                 # database connects (if database role)
docker run hello-world   # docker works (if docker role)
```

### 5. Optional: add agent layer

```bash
cd ~/.dotfiles/ansible
ansible-playbook bootstrap.yml \
  --extra-vars "@profiles/agent_addon.yml" --tags agent --ask-become-pass
```

## After migration

- [ ] Verify `dotfiles-sync` works: `dotfiles-sync` (should pull/push all repos)
- [ ] Check systemd user services: `systemctl --user list-units --state=active`
- [ ] Verify MCP servers in Claude Code: `claude mcp list`
- [ ] Test Obsidian vault syncs: `cd ~/notes/bgovault && git pull`
- [ ] Add new machine to [`ansible/inventory.yml`](ansible/inventory.yml) for remote management
- [ ] **Keep old machine running until everything is confirmed**

## Rollback

If the new machine isn't working, the old machine is untouched. No data was modified
on the source — only read + export operations.

To start fresh on the new machine:

```bash
sudo userdel -r $USER  # nuclear option
# or just re-run bootstrap (ansible is idempotent)
```

---

*Last reviewed: 2026-04-11*
