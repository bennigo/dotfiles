# Custom Scripts (local_bin)

~28 executable scripts deployed to `~/.local/bin/` via GNU Stow.

## Scripts by Category

### Obsidian / Vault
| Script | Purpose |
|--------|---------|
| `vault-create-daily` | Create daily notes from canonical template (standalone, outside Obsidian) |
| `vault-jot` | Quick capture to daily note (rofi popup or CLI mode) |
| `sway-nvim-toggle` | Toggle Neovim Obsidian scratchpad windows (today/new/quick/template modes) |
| `run_nvim_obsidian.sh` | Launch Neovim with Obsidian vault |

### Firefox / Browser
| Script | Purpose |
|--------|---------|
| `firefox-profile` | Launch/focus Firefox profiles on dedicated Sway workspaces |
| `toggle-firefox-scratchpad` | Toggle default Firefox between tiled and scratchpad |

### Media / Screenshots
| Script | Purpose |
|--------|---------|
| `sway-screenshot` | Wayland screenshot (fullscreen/window/region modes) |
| `run_screenshot.sh` | Screenshot wrapper with default directory handling |
| `run_swappy.sh` | Clipboard image annotation/editing |
| `print-md` | Markdown to PDF via pandoc + CUPS (duplex, draft, grayscale) |

### Voice / Speech
| Script | Purpose |
|--------|---------|
| `voice-input` | Speech-to-text via faster-whisper with Wayland clipboard (auto/en/is) |

### MTP / Device Mounting
| Script | Purpose |
|--------|---------|
| `mtp-automount` | MTP device automounter with friendly names (YoloBox etc.) |
| `mount-yolobox` | Convenience wrapper for YoloBox mounting |
| `umount-yolobox` | Unmount YoloBox |
| `rofi-mount-menu` | Interactive rofi UI for USB disk and MTP mount/unmount |

### Sync / Dotfiles
| Script | Purpose |
|--------|---------|
| `dotfiles-sync` | Enhanced sync: dotfiles + claude-private + password-store repos |
| `deploy-sync-scripts` | Deploy sync scripts from dotfiles to system |
| `setup-sync` | Quick setup for password-store and dotfiles sync |
| `setup-sync-complete` | Complete sync system setup with systemd timer |

### Sway / Window Management
| Script | Purpose |
|--------|---------|
| `toggle-libreoffice.sh` | Toggle LibreOffice scratchpad window |

### Office / Applications
| Script | Purpose |
|--------|---------|
| `libreoffice` | Flatpak wrapper for LibreOffice |
| `office` | Simple LibreOffice launcher |

### Claude Code
| Script | Purpose |
|--------|---------|
| `claude-notify` | Forward Claude Code notification hooks to Mako via notify-send |

### Audio / Notifications
| Script | Purpose |
|--------|---------|
| `spotify-notify` | Spotify track change notifications via playerctl + notify-send |

### System / Utility
| Script | Purpose |
|--------|---------|
| `sign-pdf` | Add signature image to PDF documents (Python) |
| `sendsshKey.sh` | SSH public key deployment helper |
| `getnf` | Nerd Font installer (third-party, maintained by trimclain) |
| `setup-family-laptop` | Create isolated credentials for family laptops |

## Dependencies

Core dependencies used across multiple scripts:

| Package | Used by |
|---------|---------|
| `rofi` | vault-jot, rofi-mount-menu, sway-nvim-toggle |
| `jq` | sway-nvim-toggle, claude-notify, firefox-profile |
| `libnotify-bin` (notify-send) | claude-notify, spotify-notify |
| `playerctl` | spotify-notify |
| `wl-clipboard` | voice-input, sway-screenshot |
| `grim` + `slurp` | sway-screenshot, run_screenshot.sh |
| `swappy` | run_swappy.sh |
| `pandoc` + `xelatex` | print-md |
| `faster-whisper` | voice-input |
| `gio` | mtp-automount |

## Adding New Scripts

1. Create script in `local_bin/.local/bin/`
2. Make executable: `chmod +x local_bin/.local/bin/your-script`
3. Redeploy: `stow -R local_bin`
4. If it has new dependencies, note them above

## Cross-References

- **Sway keybindings**: `sway/.config/sway/CLAUDE.md`
- **Systemd services**: `systemd/CLAUDE.md` (spotify-notify.service, mtp-automount@.service)
- **Claude Code hooks**: `claude-code/CLAUDE.md` (claude-notify)
- **MTP system setup**: `system/CLAUDE.md` (udev rules, helper scripts)
- **Sync workflow**: `SYNC_WORKFLOW.md`
- **Top-level overview**: `../CLAUDE.md`
