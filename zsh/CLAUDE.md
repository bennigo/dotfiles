# Zsh Configuration

Shell configuration with Zap plugin manager, modular aliases/exports, and Wayland integration.

## File Structure

```
zsh/.config/zsh/
├── .zshrc            # Main config: Zap plugins, keybinds, tool integrations
├── aliases.zsh       # Command aliases (SSH hosts, safety wrappers, navigation)
├── exports.zsh       # Environment variables, PATH, credentials, Wayland fix
├── aliases-sync.zsh  # Sync-related aliases (dotfiles-sync, sync-status)
├── hooks-sync.zsh    # Sync-related shell hooks
└── .zshenv           # Minimal env init (has stow conflict — use stow -R --ignore='\.zshenv' zsh)
```

## Plugin Manager (Zap)

Plugins loaded via `plug` in `.zshrc`:

| Plugin | Purpose |
|--------|---------|
| `zsh-users/zsh-autosuggestions` | Command suggestions from history |
| `zap-zsh/supercharge` | General enhancements |
| `zap-zsh/vim` | Vim mode |
| `zap-zsh/zap-prompt` | Prompt configuration |
| `zap-zsh/fzf` | Fuzzy finder integration |
| `zap-zsh/exa` | Modern ls replacement (eza) |
| `zsh-users/zsh-syntax-highlighting` | Syntax highlighting |
| `hlissner/zsh-autopair` | Auto-pairing brackets/quotes |
| `urbainvaes/fzf-marks` | FZF bookmarks |
| `esc/conda-zsh-completion` | Conda completions |

## Key Settings

- **History**: 1,000,000 entries (`HISTSIZE=SAVEHIST=1000000`)
- **Editor**: `nvim`
- **Terminal**: `foot`
- **Browser**: Firefox

## Custom Keybinds

| Binding | Action |
|---------|--------|
| `Ctrl+Space` | Accept autosuggestion |
| `Ctrl+H` | tmux-sessionizer (home) |
| `Ctrl+F` | tmux-sessionizer |
| `Ctrl+L` | tmux-cht |

## Notable Aliases

- **SSH hosts**: `rek`, `gpsplot`, `insar`, `strokkur`, `yang`, etc.
- **Safety wrappers**: `cp -i`, `mv -i`, `rm -i`
- **Navigation**: `j`/`f`/`z` (zoxide), `g` (lazygit), `v` (nvim)
- **Config shortcuts**: `vrc` (nvim config), `sync` (dotfiles-sync)

## PATH Extensions

Includes: Rust cargo, Go, Node.js (fnm), Neovim (custom build), miniforge3, Deno, `~/.local/bin`

## Wayland Environment Fix (`exports.zsh`)

The `refresh-wayland-env` function pulls fresh `WAYLAND_DISPLAY`, `SWAYSOCK`, and `DISPLAY`
from tmux session env. Runs automatically on shell startup when `WAYLAND_DISPLAY` is empty
inside tmux. See `tmux/.config/tmux/CLAUDE.md` for the full Wayland env architecture.

## Database Integration (`exports.zsh`)

A `pg_url` function builds PostgreSQL connection strings from `~/.pgpass` entries — used to
set MCP server environment variables for Claude Code database access.

## Stow Note

`zsh/.zshenv` has a pre-existing conflict. Deploy with:
```bash
stow -R --ignore='\.zshenv' zsh
```

## Cross-References

- **Tmux Wayland fix**: `tmux/.config/tmux/CLAUDE.md` (refresh-wayland-env, prefix + E)
- **Sync system**: `SYNC_WORKFLOW.md` (aliases-sync.zsh, hooks-sync.zsh)
- **Claude Code MCP env vars**: `claude-code/CLAUDE.md`
- **Top-level overview**: `../CLAUDE.md`
