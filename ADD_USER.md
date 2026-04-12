# Adding a User

How to add another user to an existing system with their own dotfiles deployment.

## Standard user (full dotfiles)

Use the `user` profile, which runs `base` + `dotfiles` for the target user.

```bash
# Create the user first:
sudo adduser newuser

# Run bootstrap for them:
cd ~/.dotfiles/ansible
ansible-playbook bootstrap.yml \
  --extra-vars "profile=user target_user=newuser" \
  --ask-become-pass
```

This gives `newuser`:
- Passwordless sudo
- Git identity configured
- Shell set to zsh
- Dotfiles stowed into their home directory

The `user` profile does **not** install packages (assumes the system already has them
from a previous full bootstrap). It only configures the user environment.

## Restricted agent user (no sudo, isolated)

For an AI agent or service user that should be sandboxed:

```bash
cd ~/.dotfiles/ansible
ansible-playbook bootstrap.yml \
  --extra-vars "@profiles/agent_addon.yml" --tags agent \
  --ask-become-pass
```

This creates `openclaw-agent` with:
- Home directory mode 0700 (no other user can read it)
- No sudo access
- No docker group membership
- Own workspace at `/opt/openclaw/`
- API keys in `/opt/openclaw/config/agent.env` (mode 0600)

See [`ansible/roles/agent/README.md`](ansible/roles/agent/README.md) for details
and [`PLAYBOOK_GUIDE.md`](PLAYBOOK_GUIDE.md) Recipe 3.

## Shared vs personal dotfiles

The `dotfiles` role stows the **same** dotfiles for every user. If `newuser` needs
different configs:

1. Create a branch in the dotfiles repo for their customizations
2. Or override specific stow modules: `--extra-vars "stow_directories=['zsh','tmux']"`
3. Or skip dotfiles entirely: `--skip-tags dotfiles`

## Removing a user

```bash
# Remove user + home directory:
sudo userdel -r newuser

# For agent user, also clean workspace:
sudo userdel -r openclaw-agent
sudo rm -rf /opt/openclaw /etc/logrotate.d/openclaw-agent
```

---

*Last reviewed: 2026-04-11*
