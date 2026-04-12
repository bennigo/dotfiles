# desktop

Sway Wayland desktop ecosystem. Installs the compositor, status bar, launcher, terminal
emulators, screenshot tools, media players, fonts, and optional GUI apps (Zotero,
LibreOffice via Flatpak, Obsidian via snap).

## When to run

After `base` and `development`. This is the main GUI-enabling role.

```bash
ansible-playbook bootstrap.yml --tags desktop
```

## What it installs

- **Compositor**: Sway + swaybg
- **Bar**: Waybar
- **Launcher**: Rofi
- **Notifications**: Mako
- **Terminals**: Kitty (primary), Foot (lightweight)
- **Screenshots**: grim, slurp, swappy, wl-clipboard
- **Fonts**: Nerd Fonts (JetBrains Mono, etc.)
- **Flatpak**: Zotero, LibreOffice (via Flathub)
- **Snap**: Obsidian
- **Multiplexer**: Tmux + TPM plugins
- **CLI tools**: FZF, lazygit, delta

## Dependencies

- `base`, `development` (implicitly — tmux plugins use git, Node.js for some tools)

## Key variables

- `desktop_packages` — package list (in `group_vars/all.yml`)

## Verification

```bash
sway --version
kitty --version
waybar --version
```

## See also

- [`../../sway/.config/sway/CLAUDE.md`](../../sway/.config/sway/CLAUDE.md) — compositor config, keybinds, scratchpads
- [`../../waybar/CLAUDE.md`](../../waybar/CLAUDE.md) — status bar modules
