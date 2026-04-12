# base

Essential system foundation. Updates apt, installs core packages, configures user
groups, sets up passwordless sudo, git identity, shell defaults, and PAM environment.

## When to run

Always first — every other role assumes `base` has run. Included in all profiles.

```bash
ansible-playbook bootstrap.yml --tags base
```

## What it installs

- `build-essential`, `curl`, `ca-certificates`, `gnupg`, `cmake`, `jq`
- User added to `sudo`, `input`, `video` groups
- Passwordless sudo configured
- Git `user.name` / `user.email` set from `target_user` / `target_email`

## Dependencies

None — this is the root role.

## Key variables

- `target_user` — auto-detected from `$USER`
- `target_email` — default `bgo@vedur.is`
- `base_packages` — package list (override in profile)
- `features.setup_work_infrastructure` — enables vedur.is NFS/hosts

## Verification

```bash
groups $USER          # should include sudo, input, video
git config user.name  # should match target_name
sudo -n true && echo "passwordless sudo OK"
```

## See also

- [`../CLAUDE.md`](../CLAUDE.md) — role reference table
- [`../../PLAYBOOK_GUIDE.md`](../../PLAYBOOK_GUIDE.md) — profile selection
