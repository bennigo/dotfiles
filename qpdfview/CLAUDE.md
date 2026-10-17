# qpdfview

Tabbed PDF viewer, installed by the Ansible desktop role and deployed with
`stow --no-folding qpdfview`. Keep the config directory real so runtime files
(settings, bookmarks) do not get written into the repository.

```sh
qpdfview ./*.pdf
qpdfview --unique /path/to/pdfs/*.pdf   # add to an existing instance
```

## Shortcuts

`.config/qpdfview/shortcuts.conf` is Qt QSettings INI format. qpdfview reads
`QSettings("qpdfview", "shortcuts")`; action names are `previousTab` and `nextTab`.
Comma-separated values are alternative shortcuts, not semicolon-separated text
(the latter is only the settings dialog's input format).

- **Alt+Shift+h / Alt+Shift+l:** previous/next PDF tab.
  Plain Alt+h conflicts with the Help menu mnemonic (verified in Qt6), so it
  must not be used here.
- **Ctrl+Shift+Tab / Ctrl+Tab:** retained as alternatives.
- **Arrow keys:** normal document scrolling.

Restart qpdfview after editing shortcuts. Other settings and document history
remain runtime files outside this repository. Changing shortcuts in the GUI may
rewrite this stow-managed file; check the diff before syncing.

## Zathura alternative

`zathura-tabs [DIRECTORY | PDF ...]` opens PDFs as Sway tabs on workspace `pdfs`.
Ordinary Zathura remains in the Super+z scratchpad. See
`../sway/.config/sway/CLAUDE.md` and `../local_bin/CLAUDE.md`.
