# credentials

Credential system bootstrap. Installs GPG, pass, and ansible-vault tooling. Configures
GPG agent, deploys setup scripts, and prepares directories — but does not create or
import any sensitive data (that's a manual step).

## When to run

After `base`. Run this when you need ansible-vault credential extraction (API keys,
SSH keys) or pass-based secret management.

```bash
ansible-playbook bootstrap.yml --tags credentials
```

## What it installs

- `pass`, `ansible`, `gpg`, `pinentry-curses`, `pinentry-gtk2`
- GPG agent configuration
- Setup scripts and documentation deployed to target home
- Directory structure for credentials

## Dependencies

- `base`

## Key variables

None role-specific — uses `target_user` and `target_home` from globals.

## Verification

```bash
gpg --list-secret-keys    # GPG key imported?
pass ls                   # password store initialized?
```

## See also

- [`../../system/credentials.md`](../../system/credentials.md) — GPG/pass/vault workflow
- [`../../system/emergency-recovery.md`](../../system/emergency-recovery.md) — lockout recovery
- [`../../system/add-credentials-procedure.md`](../../system/add-credentials-procedure.md) — adding new credentials
