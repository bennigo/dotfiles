# Testing Guide - Ansible Bootstrap System

Comprehensive testing procedures for the single-command Ubuntu setup system.

## 🧪 Testing Strategy

### Test Environments

**Primary Test**: Fresh Ubuntu 25.04+ VM/container
```bash
# Recommended test setup
multipass launch 25.04 --name ubuntu-test --disk 20G --memory 4G
multipass shell ubuntu-test
```

**Alternative Test Methods**:
- Docker Ubuntu 25.04 container (limited - no systemd)
- VirtualBox/VMware VM (full hardware simulation)
- Dedicated test partition (most realistic)

## 🚀 Basic Validation Tests

### 1. Prerequisites Test
```bash
# Verify clean Ubuntu system
lsb_release -a  # Should show Ubuntu 25.04+
whoami         # Should be non-root user
sudo -v        # Should prompt for password, then succeed
```

### 2. Clone and Basic Syntax Check
```bash
sudo apt update && sudo apt install -y git ansible
git clone https://github.com/your-username/dotfiles.git ~/.dotfiles
cd ~/.dotfiles/ansible

# Syntax validation
ansible-playbook bootstrap.yml --syntax-check
ansible-playbook bootstrap.yml --check -K  # Dry run
```

### 3. Hardware Detection Test
```bash
# Test detection logic
ansible localhost -m setup | grep -E "(nvidia|battery|chassis|form_factor)"

# Manual hardware info
lspci | grep -i nvidia    # GPU detection
cat /sys/class/power_supply/*/type  # Battery detection
hostnamectl | grep Chassis  # Form factor detection
```

## 📋 Component Testing

### Base System
```bash
# Test base role in isolation
ansible-playbook bootstrap.yml --tags "base" -K

# Verify results
groups $USER      # Should include sudo, docker groups
echo $SHELL       # Should be /usr/bin/zsh
ls ~/.local/bin   # Should exist with correct permissions
```

### Development Environment
```bash
# Test development role
ansible-playbook bootstrap.yml --tags "development" -K

# Verify installations
go version           # Should show Go 1.24.5+
cargo --version     # Should show Rust toolchain
node --version      # Should show Node.js LTS
python3 --version   # Should show Python 3.12+
```

### Desktop Environment
```bash
# Test desktop role (requires display)
ansible-playbook bootstrap.yml --tags "desktop" -K

# Verify Sway ecosystem
which sway waybar foot rofi  # Should all exist
systemctl --user status pipewire  # Audio system
```

### Credentials System
```bash
# Test credential preparation
ansible-playbook bootstrap.yml --tags "credentials" -K

# Verify preparation (NOT configuration)
which gpg pass ansible-vault  # Tools installed
ls ~/.dotfiles/system/scripts/ # Scripts deployed
test -f ~/CREDENTIAL_SETUP_REQUIRED.md  # Reminder created
```

## 🎛️ Profile Testing

### Minimal Profile
```bash
ansible-playbook bootstrap.yml --extra-vars "profile=minimal" -K

# Verify minimal system
! which sway        # Desktop components should NOT exist
which git ansible   # Basic tools should exist
```

### Development Profile
```bash
ansible-playbook bootstrap.yml --extra-vars "profile=development" -K

# Verify dev environment without desktop
which go cargo node python3  # Dev tools should exist
! which sway                 # Desktop should NOT exist
```

### Work Laptop Profile
```bash
ansible-playbook bootstrap.yml --extra-vars "@profiles/work_laptop.yml" -K

# Full system with laptop optimizations
systemctl status tlp          # Power management
which sway kitty lazygit     # Complete desktop
```

## 🔧 Hardware-Specific Testing

### NVIDIA GPU Testing
```bash
# Force NVIDIA setup
ansible-playbook bootstrap.yml --extra-vars "force_nvidia=true" -K

# Verify NVIDIA configuration
nvidia-smi                    # Should work
cat /etc/modprobe.d/nvidia-drm.conf  # DRM kernel mode
swaymsg -t get_outputs       # Wayland display detection
```

### Laptop Optimization Testing
```bash
# Force laptop setup
ansible-playbook bootstrap.yml --extra-vars "force_laptop=true" -K

# Verify laptop features
systemctl status tlp          # Power management
brightnessctl                # Brightness control
cat /proc/acpi/battery/*/info # Battery detection
```

## 🛠️ Error Testing

### Network Failure Simulation
```bash
# Test with limited network
sudo iptables -A OUTPUT -p tcp --dport 443 -j DROP  # Block HTTPS
ansible-playbook bootstrap.yml -K  # Should handle gracefully

# Restore network
sudo iptables -F  # Clear rules
```

### Permission Testing
```bash
# Test without sudo
ansible-playbook bootstrap.yml  # Should fail gracefully

# Test with incorrect user
sudo -u nobody ansible-playbook bootstrap.yml -K  # Should fail
```

### Partial Installation Recovery
```bash
# Simulate partial failure
ansible-playbook bootstrap.yml --tags "base,development" -K

# Test resumption
ansible-playbook bootstrap.yml --start-at-task "Install Sway and Wayland ecosystem" -K
```

## 📊 Comprehensive System Test

### Full Installation Test
```bash
# Complete system setup
time ansible-playbook bootstrap.yml -K

# Time should be ~30-45 minutes
# All tasks should report 'ok' or 'changed'
# No tasks should 'fail' or 'error'
```

### Post-Installation Validation
```bash
# System functionality
sudo reboot
# Select "Sway" from login manager

# Desktop environment test
$mod+Return      # Terminal should open
$mod+d          # Rofi should appear
$mod+Print      # Screenshot tool should work

# Development environment test
cd /tmp
echo 'fn main() { println!("Hello"); }' > test.rs
rustc test.rs && ./test  # Should compile and run

# Credential system test
cd ~/.dotfiles/system
ls scripts/      # Should contain all credential scripts
cat ~/CREDENTIAL_SETUP_REQUIRED.md  # Should have setup instructions
```

## 🔍 Debugging Failed Tests

### Ansible Debugging
```bash
# Verbose output
ansible-playbook bootstrap.yml -vvv -K

# Check specific task
ansible localhost -m setup  # Gather facts
ansible localhost -m apt -a "name=git state=present" --become

# Role isolation
ansible-playbook bootstrap.yml --tags "base" --check -K
```

### System State Debugging
```bash
# Check services
systemctl --failed        # Failed system services
systemctl --user --failed # Failed user services

# Check packages
apt list --installed | grep -E "(sway|waybar|neovim)"

# Check configurations
ls -la ~/.config/          # Stowed configurations
ls -la /etc/*.backup.*     # Backup files created
```

### Hardware Detection Debugging
```bash
# Manual hardware detection
ansible localhost -m setup | jq '.ansible_facts | {gpu: .ansible_lspci, chassis: .ansible_form_factor, battery: .ansible_env}'

# GPU detection
lspci | grep -i vga
lspci | grep -i nvidia

# Power detection
ls /sys/class/power_supply/
cat /sys/class/power_supply/*/type
```

## 📈 Performance Testing

### Installation Timing
```bash
# Measure role performance
time ansible-playbook bootstrap.yml --tags "base" -K
time ansible-playbook bootstrap.yml --tags "development" -K  
time ansible-playbook bootstrap.yml --tags "desktop" -K
```

### Resource Usage
```bash
# Monitor during installation
htop          # CPU/Memory usage
df -h         # Disk space consumption
netstat -i    # Network utilization
```

## ✅ Acceptance Criteria

### Must Pass Tests
- [ ] Fresh Ubuntu 25.04+ → Complete system in single command
- [ ] Hardware auto-detection works correctly
- [ ] All profiles install without errors
- [ ] Sway desktop environment functional after reboot
- [ ] Development tools accessible and working
- [ ] Credential system prepared (not configured)
- [ ] System can be re-run safely (idempotent)

### Performance Targets
- [ ] Total installation time < 60 minutes
- [ ] No critical package installation failures
- [ ] System boots properly after installation
- [ ] Desktop responsiveness acceptable after setup

### Security Validation
- [ ] No plaintext credentials in any files
- [ ] GPG/Pass integration working correctly
- [ ] Ansible vault properly configured
- [ ] System file permissions correct
- [ ] User groups properly configured

## 🔄 Continuous Testing

### Regular Validation
```bash
# Monthly test routine
multipass launch 25.04 --name monthly-test
# Run full installation test
# Document any issues in this file
```

### Pre-commit Testing
```bash
# Before committing changes
ansible-playbook bootstrap.yml --syntax-check
ansible-playbook bootstrap.yml --check -K  # Dry run
ansible-lint bootstrap.yml  # If ansible-lint available
```

---

**Remember**: This bootstrap system transforms a clean Ubuntu installation into a complete development environment. Test thoroughly before relying on it for important systems.