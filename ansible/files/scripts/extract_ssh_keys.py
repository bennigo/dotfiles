#!/usr/bin/env python3
"""
Extract SSH keys from Ansible vault and deploy them to ~/.ssh/
"""

import os
import sys
import yaml
import subprocess
from pathlib import Path

def run_command(cmd, input_data=None):
    """Run shell command and return output"""
    try:
        result = subprocess.run(
            cmd, shell=True,
            input=input_data,
            text=True,
            capture_output=True,
            check=True
        )
        return result.stdout.strip()
    except subprocess.CalledProcessError as e:
        print(f"Error running command '{cmd}': {e.stderr}")
        return None

def decrypt_vault(vault_path, vault_password_file=None):
    """Decrypt ansible vault and return parsed YAML"""
    cmd = "ansible-vault view"
    if vault_password_file:
        cmd += f" --vault-password-file {vault_password_file}"
    cmd += f" {vault_path}"

    output = run_command(cmd)
    if output:
        return yaml.safe_load(output)
    return None

def extract_ssh_keys(vault_data, ssh_dir):
    """Extract SSH keys from vault data and write to SSH directory"""
    ssh_path = Path(ssh_dir)
    ssh_path.mkdir(mode=0o700, exist_ok=True)

    extracted_files = []

    # Extract SSH keys section
    ssh_keys = vault_data.get('ssh_keys', {})

    for filename, content in ssh_keys.items():
        if not content:
            continue

        file_path = ssh_path / filename

        # Write file
        with open(file_path, 'w') as f:
            f.write(content)

        # Set appropriate permissions
        if filename.endswith('.pub') or filename in ['config', 'known_hosts', 'authorized_keys']:
            file_path.chmod(0o644)
        else:
            # Private keys
            file_path.chmod(0o600)

        extracted_files.append(str(file_path))
        print(f"✓ Extracted {filename}")

    return extracted_files

def main():
    if len(sys.argv) < 3:
        print("Usage: extract_ssh_keys.py <vault_file> <ssh_directory> [vault_password_file]")
        sys.exit(1)

    vault_file = sys.argv[1]
    ssh_directory = sys.argv[2]
    vault_password_file = sys.argv[3] if len(sys.argv) > 3 else None

    # Check if vault file exists
    if not os.path.exists(vault_file):
        print(f"Error: Vault file {vault_file} not found")
        sys.exit(1)

    # Decrypt vault
    print(f"Decrypting vault: {vault_file}")
    vault_data = decrypt_vault(vault_file, vault_password_file)

    if not vault_data:
        print("Error: Could not decrypt vault")
        sys.exit(1)

    # Extract SSH keys
    print(f"Extracting SSH keys to: {ssh_directory}")
    extracted_files = extract_ssh_keys(vault_data, ssh_directory)

    if extracted_files:
        print(f"\n✅ Successfully extracted {len(extracted_files)} SSH files:")
        for file_path in extracted_files:
            print(f"   {file_path}")
    else:
        print("⚠️  No SSH keys found in vault")

if __name__ == "__main__":
    main()