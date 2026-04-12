# database

PostgreSQL from the official PGDG repository. Creates a dev user with CREATEDB/CREATEROLE
privileges, a local database, and configures peer authentication.

## When to run

After `base`. Needed for any machine with local database development.

```bash
ansible-playbook bootstrap.yml --tags database
```

## What it installs

- PostgreSQL (version pinned, currently 18) from `apt.postgresql.org`
- `postgresql-contrib`, `libpq-dev`, `python3-psycopg2`
- DbVisualizer GUI client (optional)
- Credential management scripts

## Dependencies

- `base`
- `credentials` role recommended (for automated credential extraction)

## Key variables

- `postgresql_version` — default `"18"` (in `roles/database/defaults/main.yml`)
- `dbvisualizer_version` — default `"25.3.2"`
- `postgresql_auth_method` — default `"peer"`

## Verification

```bash
psql --version
sudo -u $USER psql -c "SELECT version();" $USER
```

## See also

- [`../DATABASE_SETUP.md`](../DATABASE_SETUP.md) — full setup guide with credential management
- [`../../system/credentials.md`](../../system/credentials.md) — GPG/pass/vault workflow
