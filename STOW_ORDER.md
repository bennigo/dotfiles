# Stow Deployment Order

GNU Stow deployment order for dotfiles modules. Most modules are independent and can
be deployed in any order. The exceptions are documented below.

## Modules with special requirements

| Module | Requirement | Why |
|--------|-------------|-----|
| `systemd` | `stow -R --no-folding systemd` | Without `--no-folding`, stow tree-folds `~/.config/systemd/`, which breaks `systemctl --user enable` (it can't create `.wants/` symlinks inside a stow-managed symlink) |
| `zsh` | `stow -R --ignore='\.zshenv' zsh` | Pre-existing `~/.zshenv` conflict. The `--ignore` flag tells stow to skip it. |

## Dependency ordering

```
zsh (exports.zsh sets env vars: API keys, database URLs, tool paths)
 ├── claude-code  (MCP servers read BRAVE_API_KEY, GOOGLE_MCP_*, DB URLs from env)
 └── crush        (same MCP + provider config, same env vars)
```

Everything else is a leaf — no cross-module config dependencies.

In particular, these have **no** stow-time dependencies despite seeming related:

| Module | Seems like it depends on… | Actually independent because… |
|--------|--------------------------|-------------------------------|
| neovim | zsh (shell aliases?) | Loads via Lua/LazyVim, no shell sourcing |
| tmux | zsh (shell env?) | TPM plugin manager is self-contained |
| sway | waybar, kitty, foot, mako | References binaries, not config paths |
| waybar | sway | Reads sway IPC at runtime, no config dependency |

## Recommended deployment order

```bash
# 1. Special-handling modules first
stow -R --no-folding systemd
stow -R --ignore='\.zshenv' zsh

# 2. Shell support
stow profile gnupg local_bin

# 3. Core tools (parallel, any order)
stow neovim tmux kitty foot sway waybar mako

# 4. After zsh env vars are available
stow claude-code crush

# 5. Everything else (any order)
stow docker firefox ollama grim swappy alacritty qutebrowser
```

Or deploy everything at once (Ansible does this):

```bash
stow -R --no-folding systemd
stow -R --ignore='\.zshenv' zsh
stow profile gnupg local_bin neovim tmux kitty foot sway waybar mako \
     claude-code crush docker firefox ollama grim swappy alacritty qutebrowser
```

## Ansible handles this automatically

The `dotfiles` role in `ansible/roles/dotfiles/tasks/main.yml` deploys modules via
stow with the correct flags. If you're running the bootstrap playbook, you don't need
to think about ordering — it's built in.

Manual stow is for when you're adding or re-deploying a single module outside Ansible.

## Un-stowing

```bash
stow -D <module>          # remove symlinks for one module
stow -D -R --no-folding systemd  # systemd needs the same flags to un-stow cleanly
```

Un-stowing is safe — it only removes symlinks, never deletes source files.

---

*Last reviewed: 2026-04-11*
