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

## Dependencies

- `base`

## Key variables

- `go_version` — Go version to install (in `group_vars/all.yml`)
- `development_packages` — additional dev packages
- `features.setup_personal_repos` — clone bgovault and other personal repos

## Verification

```bash
go version && rustc --version && node --version && python3 --version && nvim --version
```

## See also

- [`../CLAUDE.md`](../CLAUDE.md) — role reference
- [`../../neovim/.config/nvim/CLAUDE.md`](../../neovim/.config/nvim/CLAUDE.md) — Neovim plugin ecosystem
