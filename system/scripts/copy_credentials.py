#!/usr/bin/env python3
"""
Credential Migration Script

This script copies credentials from the .credentials_and_logins directory
into a structured YAML format for Ansible Vault encryption.

Usage: python3 copy_credentials.py
Prerequisites: credentials_template.yml must exist
"""

import os
import yaml
import base64
import sys

def read_file_content(file_path):
    """
    Safely read file content, handling both text and binary files.
    Returns text content or base64 encoded binary content.
    """
    try:
        # First try as text
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read().strip()
            # If content looks like binary data, re-read as binary
            if '\x00' in content:  # Null bytes indicate binary
                raise UnicodeDecodeError("Binary content detected", b"", 0, 0, "")
            return content
    except UnicodeDecodeError:
        # Read as binary and base64 encode
        with open(file_path, 'rb') as f:
            content = f.read()
            return base64.b64encode(content).decode('utf-8')
    except Exception as e:
        print(f"Error reading {file_path}: {e}")
        return None

def main():
    # Check if template exists
    if not os.path.exists('credentials_template.yml'):
        print("Error: credentials_template.yml not found")
        print("Run ./setup_vault.sh first to create the template")
        sys.exit(1)
    
    # Read the template
    try:
        with open('credentials_template.yml', 'r') as f:
            template = yaml.safe_load(f)
    except Exception as e:
        print(f"Error reading template: {e}")
        sys.exit(1)

    # Directory containing credentials
    creds_dir = ".credentials_and_logins"
    if not os.path.exists(creds_dir):
        print(f"Error: {creds_dir} directory not found")
        sys.exit(1)

    # Map of file names to template keys
    file_mapping = {
        'afreksnefnd_email.txt': 'afreksnefnd_email',
        'azores.login': 'azores_login',
        'benedikt_klifursamband_login': 'benedikt_klifursamband_login',
        'flug_myidtravel.txt': 'flug_myidtravel',
        'google_oauth_client.txt': 'google_oauth_client',
        'launaskjal': 'launaskjal',
        'openai_nvim_key.txt': 'openai_nvim_key',
        'pgdev.vedur.is.txt': 'pgdev_vedur_is',
        'verslo_fjarnam.txt': 'verslo_fjarnam',
        'client_secret_311376334639-11vl3n2ioavagoauc31a19abi06tqsn8.apps.googleusercontent.com.json': 'client_secret_google',
        'connections.json': 'connections_json'
    }

    print("Copying credentials to YAML structure...")
    copied_count = 0

    # Copy individual credential files
    for filename, template_key in file_mapping.items():
        file_path = os.path.join(creds_dir, filename)
        if os.path.exists(file_path):
            content = read_file_content(file_path)
            if content is not None:
                template['credentials'][template_key] = content
                print(f"✓ Copied {filename} -> {template_key}")
                copied_count += 1
            else:
                print(f"✗ Failed to read {filename}")
        else:
            print(f"⚠ Warning: {filename} not found")

    # Handle SSH keys directory
    ssh_keys_dir = os.path.join(creds_dir, "ssh_keys")
    if os.path.exists(ssh_keys_dir):
        if 'ssh_keys' not in template or template['ssh_keys'] is None:
            template['ssh_keys'] = {}
        
        ssh_files = []
        try:
            ssh_files = os.listdir(ssh_keys_dir)
        except PermissionError:
            print(f"⚠ Warning: Permission denied accessing {ssh_keys_dir}")
        
        for ssh_file in ssh_files:
            ssh_file_path = os.path.join(ssh_keys_dir, ssh_file)
            if os.path.isfile(ssh_file_path):
                content = read_file_content(ssh_file_path)
                if content is not None:
                    template['ssh_keys'][ssh_file] = content
                    print(f"✓ Copied ssh_keys/{ssh_file}")
                    copied_count += 1
                else:
                    print(f"✗ Failed to read ssh_keys/{ssh_file}")

    # Write the populated template
    output_file = 'credentials_populated.yml'
    try:
        with open(output_file, 'w') as f:
            yaml.dump(template, f, default_flow_style=False, allow_unicode=True)
        print(f"\n✅ Successfully created {output_file}")
        print(f"   Total items copied: {copied_count}")
        print(f"\nNext steps:")
        print(f"1. Review the content: less {output_file}")
        print(f"2. Encrypt: ansible-vault encrypt --vault-password-file ./scripts/ansible-vault-pass.sh {output_file}")
        print(f"3. Rename: mv {output_file} credentials.vault")
    except Exception as e:
        print(f"✗ Error writing {output_file}: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()