# email

NeoMutt email client foundation. Installs NeoMutt, mail utilities, creates mail
directories, and prepares GPG/pass integration. Does not configure accounts — that
requires manual credential setup.

## When to run

After `base` and `credentials`. Only needed on machines where you read email.

```bash
ansible-playbook bootstrap.yml --tags email
```

## What it installs

- `neomutt`, `lynx`, `w3m`, `urlview`, `ca-certificates`
- Mail directories: `~/.local/share/mail/gmail`, `~/.cache/neomutt`

## Dependencies

- `base`
- `credentials` (recommended — GPG/pass integration for account passwords)

## Verification

```bash
which neomutt
ls ~/.local/share/mail/
```

## See also

- [`../../neomutt/`](../../neomutt/) — NeoMutt configuration (needs post-reinstall setup)
- [`../../system/CLAUDE.md`](../../system/CLAUDE.md) — post-reinstall TODO for email
