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
| `development` | Dev environment | base, system_files, development, dotfiles |
| `desktop` | Full desktop | base, system_files, development, desktop, dotfiles |
| `full` | Everything | All roles including credentials |
| `work_laptop` | Work-specific | Full + work tools + laptop optimizations |

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

The system is designed to be easily extensible while maintaining the single-command bootstrap experience.