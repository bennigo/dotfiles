# Firefox Multi-Profile Setup

Multi-profile Firefox configuration with Sway workspace integration and privacy-focused defaults.

## Architecture

Three isolated Firefox profiles, each with its own `user.js` settings:

| Profile | Persistence | Workspace | Purpose |
|---------|-------------|-----------|---------|
| `default` | None (throwaway) | Scratchpad | Quick browsing, disposable sessions |
| `personal` | Session restore | 3 | Personal browsing with Firefox Sync |
| `work` | Session restore | 2 | Work browsing with Firefox Sync |

## Profile Settings (user.js)

**Common to all profiles:**
- Tracking protection enabled (`privacy.trackingprotection.enabled`)
- Shell check disabled (not default browser)

**Personal & Work profiles additionally:**
- Session restore on startup (`browser.startup.page = 3`)
- Multi-Account Containers enabled
- Welcome/onboarding pages disabled

## Deployment

Profiles are deployed to the Snap Firefox installation path:

```bash
# Run the deployment script
./deploy-firefox-profiles.sh
```

This copies `user.js` files to `~/.snap/firefox/common/.mozilla/firefox/<profile-dir>/`.
After deployment, sign into Firefox Sync in personal and work profiles to restore
bookmarks, passwords, and extensions.

**Note**: The deploy script detects existing profile directories by name prefix matching.
If profiles don't exist yet, create them in Firefox's `about:profiles` first.

## Sway Integration

### Keybindings
- `$mod+Shift+b` — Toggle default Firefox between tiled and scratchpad mode

### Workspace Assignments
- Firefox work profile → workspace 2
- Firefox personal profile → workspace 3

### Related Scripts (in `local_bin/`)
- **`firefox-profile`** — Launches a named profile on its assigned workspace, focuses if already running
- **`toggle-firefox-scratchpad`** — Toggles default Firefox between tiled window and scratchpad visibility

## Files

```
firefox/
├── CLAUDE.md
├── deploy-firefox-profiles.sh    # Profile deployment automation
└── profiles/
    ├── default.user.js           # Throwaway profile settings
    ├── personal.user.js          # Personal profile (session restore, containers)
    └── work.user.js              # Work profile (session restore, containers)
```

## Cross-References

- **Sway keybindings**: `sway/.config/sway/CLAUDE.md`
- **Launcher scripts**: `local_bin/CLAUDE.md` (firefox-profile, toggle-firefox-scratchpad)
- **Top-level overview**: `../CLAUDE.md`
