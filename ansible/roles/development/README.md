# development

Multi-language development environment. Installs Go, Rust, Node.js (fnm), Python (uv,
pipx, mamba), R, Deno, Neovim from source, and Claude Code CLI.

## When to run

After `base`. Core role for any machine where you write code.

```bash
ansible-playbook bootstrap.yml --tags development
```

## What it installs

- **Go** — version pinned in `go_version` (currently 1.24.5)
- **Rust** — via rustup (stable toolchain)
- **Node.js** — via fnm (LTS version)
- **Python** — uv, pipx, mamba/miniforge
- **R** — from distro packages
- **Neovim** — built from source (latest stable)
- **Deno** — via install script
- **Claude Code** — `@anthropic-ai/claude-code` via npm
- **GMT** — Generic Mapping Tools, built from source (see below)

## GMT (Generic Mapping Tools) + pygmt

Scientific mapping toolchain for the GPS/GNSS stack (`gps_plot` velocity/model
maps). Built from source as a **leaf under `~/git/gmt/install`** (not
system-wide) with all GIS libraries compiled in (GDAL, GEOS, PROJ, netCDF,
FFTW, PCRE2, LAPACK/BLAS) and the full **GSHHG** (coastlines/rivers/borders,
all 5 resolutions) + **DCW** (country/state polygons) data staged for offline
use. Tasks live in [`tasks/gmt.yml`](tasks/gmt.yml); run just this part with:

```bash
ansible-playbook bootstrap.yml --tags gmt          # whole GMT block
ansible-playbook bootstrap.yml --tags gmt-data     # only re-stage GSHHG/DCW
```

**Ubuntu 26.04 ghostscript caveat (handled):** the hardened `gs` AppArmor
profile denies `gs` read access to GMT's `gmt_<n>.ps-` scratch files (the
trailing dash falls outside the `@{gs_file_ext}` whitelist), breaking
`psconvert` with *"error 79 / /undefinedfilename … Permission denied"*. The role
installs a minimal local override (`/etc/apparmor.d/local/gs`, tag `apparmor`)
granting `gs` access to `~/.gmt/**` only, and reloads the profile.

**pygmt** is cloned to `~/git/pygmt` at the pinned tag. It is installed
*editable* into the consuming project's uv env as a documented dev step (it is
not installed globally, since the target venv depends on the gpslibrary
checkout):

```bash
cd ~/work/projects/gpslibrary/gps_plot
uv sync --extra maps            # portable dep: pygmt from PyPI
uv pip install -e ~/git/pygmt   # dev override: editable from the local clone
```

Runtime env (`PATH` + `GMT_LIBRARY_PATH`, the latter is how pygmt finds
`libgmt.so`) is set by the zsh exports (`zsh/.config/zsh/exports.zsh`).

## Dependencies

- `base`

## Key variables

- `go_version` — Go version to install (in `group_vars/all.yml`)
- `development_packages` — additional dev packages
- `gmt_version` / `gshhg_version` / `dcw_version` / `pygmt_version` — pinned
  GMT-stack versions (in `defaults/main.yml`)
- `features.setup_personal_repos` — clone bgovault and other personal repos

## Verification

```bash
go version && rustc --version && node --version && python3 --version && nvim --version
# GMT stack (needs the zsh exports sourced for PATH + GMT_LIBRARY_PATH):
gmt --version && gmt coast -R-25/-13/63/67 -JM4i -Gtan -Df -png /tmp/ice && echo GMT-OK
```

## See also

- [`../CLAUDE.md`](../CLAUDE.md) — role reference
- [`../../neovim/.config/nvim/CLAUDE.md`](../../neovim/.config/nvim/CLAUDE.md) — Neovim plugin ecosystem
