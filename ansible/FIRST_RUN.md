# First-run on a fresh machine

Step-by-step procedure for bootstrapping a brand-new Ubuntu 26.04 (Resolute Raccoon)
laptop into a full `work_laptop` + `agent_addon` setup.

## Overview

Two phases:
1. **Phase 1 — `work_laptop` profile:** full desktop (Sway + development + docker + PostgreSQL
   + credentials + email + dotfiles). ~15–30 min.
2. **Phase 2 — `agent_addon` profile:** layers `openclaw-agent` restricted user on top,
   without touching firewall/vault/home-perms for the primary `bgo` user. ~5 min.

First run should always be executed **locally on the target machine** (sitting at it or
over plain SSH). Once credentials + SSH keys are in place, future runs can be driven
remotely from another machine via `inventory.yml`.

---

## Prerequisites

Collect these **before** starting — some are needed mid-run, and it's painful to realize
you're blocked after you've already typed the sudo password three times.

### On the source machine (old ThinkPad)

1. **GPG private key** for git-crypt (`0FA08B1A9096B394`):
   ```bash
   gpg --export-secret-keys --armor 0FA08B1A9096B394 > /tmp/git-crypt-key.asc
   ```
   Transfer `/tmp/git-crypt-key.asc` to the new machine via USB stick or `scp`
   (do not email or leave in cloud storage). **Delete `/tmp/git-crypt-key.asc` after transfer.**

2. **ansible-vault password** — whatever `system/scripts/ansible-vault-pass.sh` reads
   from. If it's stored in `pass`, see step 3.

3. **Password store** (`~/.password-store`): this is a separate git repo, not part of
   dotfiles. Either clone from your password-store remote after phase 1, or rsync
   the directory manually:
   ```bash
   rsync -av ~/.password-store/ newlaptop:~/.password-store/
   ```

### On the target machine (fresh Ubuntu 26.04)

- User `bgo` exists (created during Ubuntu install)
- Network connectivity (wired or wi-fi configured in installer)
- SSH server running if you plan to drive from elsewhere: `sudo apt install -y openssh-server`

---

## Phase 1: work_laptop bootstrap

### 1. Install the minimum needed to run ansible

```bash
sudo apt update
sudo apt install -y git stow ansible python3-apt git-crypt gnupg
```

### 2. Clone dotfiles and initialize submodules

```bash
git clone https://github.com/bennigo/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
git submodule update --init --recursive
```

The `claude-private` submodule will clone but files will be **encrypted** until you
unlock git-crypt in the next step.

### 3. Unlock git-crypt (so claude-private submodule is usable)

```bash
# Import GPG key from USB/transferred file
gpg --import /path/to/git-crypt-key.asc

# Verify the key imported
gpg --list-secret-keys 0FA08B1A9096B394

# Unlock the submodule
cd ~/.dotfiles/claude-private
git-crypt unlock

# Confirm: these files should now be readable plaintext, not binary garbage
head -1 *.md 2>/dev/null
cd ~/.dotfiles
```

### 4. Pre-populate vault password reader (if using `pass`)

If `system/scripts/ansible-vault-pass.sh` reads from `pass`, you need the password store
available **before** the credentials role runs. Either:

```bash
# Option a: clone password store from your remote
git clone git@github.com:bennigo/pwstore.git ~/.password-store

# Option b: rsync from old machine (run on old machine):
rsync -av ~/.password-store/ bgo@newlaptop:~/.password-store/
```

### 5. Run the playbook

```bash
cd ~/.dotfiles/ansible
ansible-playbook bootstrap.yml \
  --extra-vars "profile=work_laptop" \
  --ask-become-pass
```

**What to expect:**
- Hardware detection pause (10s) — confirm laptop + NVIDIA GPU flags
- Base packages (~5 min)
- PostgreSQL 18 from apt.postgresql.org (`resolute-pgdg` pocket)
- Docker Engine from official repo
- Desktop packages (Sway, Waybar, Rofi, Mako, etc.)
- GNU Stow deployment of all dotfile directories
- Credential role reads from `credentials.vault` via the vault-pass script

**Common first-run hiccups:**

| Symptom | Fix |
|---------|-----|
| `UNABLE TO DECRYPT` in credentials role | Vault password file not readable — fix `system/scripts/ansible-vault-pass.sh` |
| NVIDIA driver 580 not found | Override: `--extra-vars "profile=work_laptop nvidia_driver_version=590"` |
| PostgreSQL `resolute-pgdg` 404 | PGDG not yet published for 26.04 — wait, or pin to `postgresql_version=17` |
| Stow conflict on `.zshenv` | See memory: run `stow -R --ignore='\.zshenv' zsh` manually after bootstrap |

### 6. Reboot

```bash
sudo reboot
```

After reboot, log in as `bgo`. Sway should load via greetd/sway-session. Verify:

```bash
echo $XDG_SESSION_TYPE   # should be "wayland"
swaymsg -t get_version   # sway talks back
```

---

## Phase 2: agent_addon layer

### 1. Run agent-only playbook

```bash
cd ~/.dotfiles/ansible
ansible-playbook bootstrap.yml \
  --extra-vars "@profiles/agent_addon.yml" --tags agent \
  --ask-become-pass
```

This **only** runs the `agent` role and creates:
- `openclaw-agent` system user (0700 home, no sudo, no docker group)
- `/opt/openclaw/{logs,data,config}` workspace
- fnm + Node.js LTS + `@anthropic-ai/claude-code` + `openclaw` npm packages
- `/opt/openclaw/config/agent.env` with API keys extracted from vault
- `/etc/logrotate.d/openclaw-agent`
- `/home/bgo/AGENT_SERVER_GUIDE.md` (your operational runbook)

**It does NOT touch:**
- UFW / firewall (would break desktop networking)
- `~/notes/bgovault` (no push disable, no lockfile)
- `/home/bgo` permissions (stays 0755)
- Tailscale

### 2. Verify isolation end-to-end

```bash
# User exists, no sudo
getent passwd openclaw-agent
sudo -l -U openclaw-agent 2>&1 | grep -q "not allowed" && echo "✓ no sudo"

# Not in docker group
groups openclaw-agent   # should only show "openclaw-agent"

# Cannot read /home/bgo
sudo -u openclaw-agent ls /home/bgo 2>&1 | grep -q "Permission denied" && echo "✓ home isolated"

# Node.js + packages work
sudo -u openclaw-agent bash -lc 'export PATH=$HOME/.local/share/fnm:$PATH; eval "$(fnm env)"; node --version && openclaw --version'

# API keys present and readable by agent only
sudo -u openclaw-agent test -r /opt/openclaw/config/agent.env && echo "✓ env readable"
sudo stat -c '%a %U' /opt/openclaw/config/agent.env   # expect: 600 openclaw-agent
```

### 3. First-time OpenClaw onboarding (manual)

OpenClaw's daemon install requires interactive input, so it's kept out of the playbook:

```bash
sudo -u openclaw-agent -i
export PATH=$HOME/.local/share/fnm:$PATH && eval "$(fnm env)"
source /opt/openclaw/config/agent.env
openclaw onboard --install-daemon
openclaw agents list --bindings
```

---

## Post-install checklist

- [ ] `dotfiles-sync` works (git pull/push on all tracked repos)
- [ ] Waybar shows git-sync status correctly
- [ ] `~/.password-store` populated and `pass ls` works
- [ ] `psql bgo` connects
- [ ] `docker run hello-world` works (as bgo)
- [ ] `sudo -u openclaw-agent bash` drops into restricted shell
- [ ] Read `~/AGENT_SERVER_GUIDE.md` and review the Progressive Hardening roadmap
- [ ] Add the new machine to `inventory.yml` for remote management from ThinkPad

---

## Driving future runs from ThinkPad (after first run)

Once the new machine has SSH keys and passwordless sudo set up by phase 1, you can
re-run any part of the playbook remotely:

```bash
# On ThinkPad
cd ~/.dotfiles/ansible
ansible-playbook bootstrap.yml -i inventory.yml \
  --extra-vars "@profiles/agent_addon.yml" --tags agent \
  --limit newlaptop
```

See the commented `agent_servers` stanza in `inventory.yml` for the host template.

---

## Rollback

If phase 2 goes wrong and you want to remove the agent layer:

```bash
sudo systemctl stop user-$(id -u openclaw-agent).slice 2>/dev/null
sudo pkill -KILL -u openclaw-agent
sudo userdel -r openclaw-agent
sudo rm -rf /opt/openclaw /etc/logrotate.d/openclaw-agent
rm -f ~/AGENT_SERVER_GUIDE.md
```

Re-run phase 2 when you're ready.
