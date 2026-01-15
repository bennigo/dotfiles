# Ansible Bootstrap System

Single-command Ubuntu setup that detects hardware and configures your complete system.

## 🚀 Quick Start

### Basic Setup (Desktop Profile)
```bash
# On fresh Ubuntu 25.04+ system:
sudo apt update && sudo apt install -y git ansible
git clone https://github.com/your-repo/dotfiles.git ~/.dotfiles
cd ~/.dotfiles/ansible
ansible-playbook bootstrap.yml -K
```

### Specific Profiles
```bash
# Minimal headless setup
ansible-playbook bootstrap.yml --extra-vars "profile=minimal" -K

# Full work laptop setup
ansible-playbook bootstrap.yml --extra-vars "@profiles/work_laptop.yml" -K

# Development environment only
ansible-playbook bootstrap.yml --extra-vars "profile=development" -K
```

## 🧩 Modular Usage

### Run Specific Components
```bash
# Only install base system + development tools
ansible-playbook bootstrap.yml --tags "base,development" -K

# Only desktop environment setup
ansible-playbook bootstrap.yml --tags "desktop" -K

# Skip heavy packages
ansible-playbook bootstrap.yml --skip-tags "heavy" -K
```

### Hardware-Specific Control
```bash
# Force NVIDIA setup even if not detected
ansible-playbook bootstrap.yml --extra-vars "force_nvidia=true" -K

# Force laptop configuration
ansible-playbook bootstrap.yml --extra-vars "force_laptop=true" -K

# Skip all hardware-specific setup
ansible-playbook bootstrap.yml --extra-vars "skip_hardware_specific=true" -K
```

## 📋 Available Profiles

| Profile | Description | Includes |
|---------|-------------|----------|
| `minimal` | Headless/server | base, dotfiles |
| `development` | Dev environment | base, system_files, development, database, dotfiles |
| `desktop` | Full desktop | base, system_files, development, database, desktop, dotfiles |
| `full` | Everything | All roles including credentials and database |
| `work_laptop` | Work-specific | Full + work tools + laptop optimizations + database |

## 🔧 Hardware Detection

The system automatically detects:

- **GPU**: NVIDIA, Intel, AMD
- **Form Factor**: Laptop vs Desktop  
- **Power**: Battery presence
- **CPU**: Intel vs AMD

Hardware-specific roles are automatically enabled based on detection.

## 🏗️ Architecture

```
roles/
├── base/              # User setup, essential packages
├── system_files/      # Deploy /etc and /usr configurations
├── development/       # Language runtimes, dev tools
├── database/          # PostgreSQL with secure credential management
├── desktop/          # Sway desktop environment
├── credentials/      # GPG, pass, vault setup
├── dotfiles/         # Stow deployment
└── hardware/         # Hardware-specific configurations
    ├── nvidia/       # NVIDIA GPU setup
    ├── laptop/       # Laptop power management
    └── desktop/      # Desktop audio/peripherals
```

## 🎛️ Customization

### Override Variables
```bash
# Custom package lists
--extra-vars "additional_base_packages=['custom-tool','another-tool']"

# Feature toggles
--extra-vars "install_gaming_tools=true install_media_tools=false"

# Hardware overrides
--extra-vars "force_nvidia=true force_laptop=false"
```

## 👥 Multi-User Support

The playbook automatically detects the current user and adjusts configuration paths accordingly.

### Target User Detection
```bash
# Automatically uses current $USER
ansible-playbook bootstrap.yml -K

# Override for a different user
ansible-playbook bootstrap.yml -K --extra-vars "target_user=johndoe"
```

**Important:** Always use `ansible-playbook -K` (asks for sudo password), not `sudo ansible-playbook` which would set USER to root.

### Personal vs Generic Configuration

Some configuration is specific to the repository owner (bgo) and is automatically skipped for other users:

| Feature | Controlled By | Default |
|---------|---------------|---------|
| Obsidian vault (bgovault) | `features.setup_personal_repos` | `true` for bgo, `false` for others |
| Personal git settings | `features.setup_personal_repos` | `true` for bgo, `false` for others |

```bash
# For other users - personal repos automatically skipped
ansible-playbook bootstrap.yml -K  # Just works!

# Force skip personal even for bgo
ansible-playbook bootstrap.yml -K --skip-tags personal

# Or via extra vars
ansible-playbook bootstrap.yml -K --extra-vars '{"features": {"setup_personal_repos": false}}'
```

### Setting Up Additional Users

For additional users on an already-configured system (packages already installed):

```bash
# IMPORTANT: Run from the ansible directory!
cd ~/.dotfiles/ansible

# Step 1: Deploy dotfiles only (lightweight, no packages)
ansible-playbook bootstrap.yml -K --extra-vars "profile=user"

# Step 2: Install per-user applications (kitty, etc.)
ansible-playbook bootstrap.yml -K --tags "kitty"
```

**Why two commands?** The `profile=user` only runs the `dotfiles` role, but kitty is in the `desktop` role. Tags filter tasks *within* roles, so you need separate runs.

**Per-user applications** (installed to ~/.local, need to run for each user):
- `kitty` - Terminal emulator
- `fnm` - Node.js version manager
- `cargo/rust` - Rust toolchain

### Customizing for Your Own Use

To adapt this playbook for your own personal repositories:

1. Fork/copy the repository
2. Edit `group_vars/all.yml`:
   ```yaml
   target_email: "your@email.com"
   target_name: "Your Name"
   features:
     setup_personal_repos: "{{ target_user == 'yourusername' }}"
   ```
3. Update repository URLs in `roles/development/tasks/main.yml`

### Custom Profiles
Create `profiles/custom.yml`:
```yaml
profile: custom
force_laptop: true
features:
  install_development_tools: true
  install_custom_feature: true
additional_packages:
  - my-custom-tool
```

## 🔒 Credentials Integration

The bootstrap sets up the credential system but doesn't configure it:

```bash
# After bootstrap, setup credentials:
cd ~/.dotfiles/system
./scripts/setup_vault.sh

# Then encrypt existing credentials:
python3 scripts/copy_credentials.py
ansible-vault encrypt --vault-password-file ./scripts/ansible-vault-pass.sh credentials_populated.yml
mv credentials_populated.yml credentials.vault
```

## 🐛 Troubleshooting

### Hardware Detection Issues
```bash
# Check what was detected
ansible localhost -m setup | grep -E "(nvidia|battery|chassis)"

# Override detection
--extra-vars "force_nvidia=true force_laptop=true"
```

### Role-Specific Issues
```bash
# Run only specific role with verbose output  
ansible-playbook bootstrap.yml --tags "nvidia" -vvv -K

# Skip problematic roles
ansible-playbook bootstrap.yml --skip-tags "nvidia,laptop" -K
```

### Package Installation Failures
```bash
# Update package cache first
sudo apt update

# Run with verbose output to see which package failed
ansible-playbook bootstrap.yml -vvv -K
```

### Mamba/Miniforge Issues

The playbook installs Miniforge (mamba) for Python environment management. If you encounter issues:

```bash
# Re-run just the mamba installation
ansible-playbook bootstrap.yml --tags "mamba" -K

# Manual installation (if ansible fails)
wget https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh
bash Miniforge3-Linux-x86_64.sh -b -p ~/.miniforge
~/.miniforge/bin/mamba shell init --shell bash --root-prefix ~/.miniforge
~/.miniforge/bin/mamba shell init --shell zsh --root-prefix ~/.miniforge
source ~/.bashrc
```

**Note:** Mamba 2.x uses `mamba shell init --shell bash --root-prefix <path>` instead of the old `mamba init bash` syntax.

## 📈 Extending the System

### Add New Hardware Support
1. Create `roles/hardware/new_hardware/`
2. Add detection logic to `inventory.yml`
3. Add to `group_vars/all.yml` hardware_roles section

### Add New Software Roles
1. `ansible-galaxy init roles/new_feature`  
2. Add to profiles in `group_vars/all.yml`
3. Update bootstrap.yml to include the role

### Custom Hooks
Place files in `roles/*/files/hooks/` for custom pre/post setup logic.

## 🗄️ Database Setup

The database role installs PostgreSQL with secure credential management:

```bash
# Database-only installation
ansible-playbook bootstrap.yml --tags "database"

# Setup credentials after installation
git clone git@github.com:bennigo/bgo-pstore.git ~/.password-store
update-pgpass
```

**Features:**
- PostgreSQL 18 from official repository
- Development user with appropriate privileges
- Secure credential storage using GPG-encrypted `pass`
- Version control safe configuration (no hardcoded passwords)
- Native PostgreSQL authentication via `.pgpass`

**Documentation:** See [DATABASE_SETUP.md](DATABASE_SETUP.md) for complete setup guide.

The system is designed to be easily extensible while maintaining the single-command bootstrap experience.