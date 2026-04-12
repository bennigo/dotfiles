# docker

Official Docker Engine installation (not `docker.io` from Ubuntu repos). Removes
conflicting packages, adds Docker GPG key + repository, installs docker-ce with
buildx and compose plugins.

## When to run

After `base`. Needed for container workloads.

```bash
ansible-playbook bootstrap.yml --tags docker
```

## What it installs

- `docker-ce`, `docker-ce-cli`, `containerd.io`
- `docker-buildx-plugin`, `docker-compose-plugin`
- Adds user to `docker` group
- Deploys `daemon.json` with overlay2 storage, systemd cgroups, DNS, log rotation

## Dependencies

- `base`

## Key variables

- `docker_log_max_size` — default `"10m"`
- `docker_log_max_files` — default `3`
- `docker_storage_driver` — default `"overlay2"`

## Verification

```bash
docker --version
docker compose version
docker run hello-world
```

## See also

- [`../../docker/CLAUDE.md`](../../docker/CLAUDE.md) — daemon config, compose templates, VPN networking
