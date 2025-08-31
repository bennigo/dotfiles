#!/bin/bash

# Ansible Vault password script using pass
# This script retrieves the vault password from the pass password manager
# Usage: Set ANSIBLE_VAULT_PASSWORD_FILE to this script path

PASS_ENTRY="ansible/vault"

# Check if pass is available
if ! command -v pass >/dev/null 2>&1; then
    echo "Error: pass is not installed" >&2
    exit 1
fi

# Check if pass is initialized
if ! pass ls >/dev/null 2>&1; then
    echo "Error: pass is not initialized. Run 'pass init <gpg-id>' first" >&2
    exit 1
fi

# Try to retrieve the password
if ! pass show "$PASS_ENTRY" 2>/dev/null; then
    echo "Error: Password entry '$PASS_ENTRY' not found in pass" >&2
    echo "Create it with: pass insert $PASS_ENTRY" >&2
    exit 1
fi