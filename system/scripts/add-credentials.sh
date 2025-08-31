#!/bin/bash

# add-credentials.sh - Interactive script to add/edit credentials safely
# This script handles the decrypt → edit → encrypt → commit workflow

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
VAULT_FILE="credentials.vault"
VAULT_PASS_SCRIPT="./scripts/ansible-vault-pass.sh"
TEMP_FILE="credentials_temp.yml"
BACKUP_FILE="credentials_backup_$(date +%Y%m%d_%H%M%S).yml"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to cleanup temp files
cleanup() {
    if [[ -f "$TEMP_FILE" ]]; then
        rm -f "$TEMP_FILE"
        print_status "Cleaned up temporary files"
    fi
}

# Trap to ensure cleanup on exit
trap cleanup EXIT

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check if we're in the right directory
    if [[ ! -f "$VAULT_FILE" ]]; then
        print_error "Vault file '$VAULT_FILE' not found. Are you in the system/ directory?"
        exit 1
    fi
    
    # Check if vault password script exists
    if [[ ! -f "$VAULT_PASS_SCRIPT" ]]; then
        print_error "Vault password script '$VAULT_PASS_SCRIPT' not found"
        exit 1
    fi
    
    # Test vault password retrieval
    if ! "$VAULT_PASS_SCRIPT" >/dev/null 2>&1; then
        print_error "Failed to retrieve vault password. Check your pass setup."
        exit 1
    fi
    
    # Check if ansible-vault is available
    if ! command -v ansible-vault >/dev/null 2>&1; then
        print_error "ansible-vault command not found. Install ansible package."
        exit 1
    fi
    
    print_success "All prerequisites satisfied"
}

# Function to create backup
create_backup() {
    print_status "Creating backup of current vault..."
    cp "$VAULT_FILE" "$BACKUP_FILE"
    print_success "Backup created: $BACKUP_FILE"
}

# Function to decrypt vault
decrypt_vault() {
    print_status "Decrypting vault file..."
    if ansible-vault decrypt --vault-password-file "$VAULT_PASS_SCRIPT" --output "$TEMP_FILE" "$VAULT_FILE"; then
        print_success "Vault decrypted successfully"
    else
        print_error "Failed to decrypt vault"
        exit 1
    fi
}

# Function to show current structure
show_structure() {
    print_status "Current vault structure:"
    echo "----------------------------------------"
    
    # Show credential categories
    echo -e "${YELLOW}Available sections:${NC}"
    grep -E "^[a-zA-Z_]+:" "$TEMP_FILE" | sed 's/:.*$//' | sort | while read -r section; do
        count=$(grep -A 100 "^$section:" "$TEMP_FILE" | grep -E "^  [a-zA-Z_]" | wc -l)
        echo "  • $section ($count items)"
    done
    
    echo "----------------------------------------"
    
    # Show recent additions (last 10 entries in credentials section)
    echo -e "${YELLOW}Recent credential entries:${NC}"
    grep -A 100 "^credentials:" "$TEMP_FILE" | grep -E "^  [a-zA-Z_]" | tail -10 | while read -r line; do
        key=$(echo "$line" | cut -d: -f1 | sed 's/^  //')
        echo "  • $key"
    done
    echo "----------------------------------------"
}

# Function to add new credential interactively
add_credential() {
    echo
    print_status "Adding new credential..."
    echo
    
    # Get credential name
    read -p "Enter credential name (e.g., 'new_api_key', 'service_login'): " cred_name
    
    if [[ -z "$cred_name" ]]; then
        print_error "Credential name cannot be empty"
        return 1
    fi
    
    # Validate name (alphanumeric and underscores only)
    if [[ ! "$cred_name" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
        print_error "Invalid credential name. Use only letters, numbers, and underscores."
        return 1
    fi
    
    # Check if credential already exists
    if grep -q "^  $cred_name:" "$TEMP_FILE"; then
        print_warning "Credential '$cred_name' already exists!"
        read -p "Do you want to replace it? (y/N): " replace
        if [[ ! "$replace" =~ ^[Yy]$ ]]; then
            print_status "Operation cancelled"
            return 1
        fi
    fi
    
    # Choose section
    echo
    echo "Available sections:"
    echo "1) credentials (default)"
    echo "2) ssh_keys"
    echo "3) other (specify)"
    read -p "Select section (1-3) [1]: " section_choice
    
    case "${section_choice:-1}" in
        1) section="credentials" ;;
        2) section="ssh_keys" ;;
        3) 
            read -p "Enter section name: " custom_section
            if [[ -z "$custom_section" ]]; then
                print_error "Section name cannot be empty"
                return 1
            fi
            section="$custom_section"
            ;;
        *) 
            print_error "Invalid choice"
            return 1
            ;;
    esac
    
    # Get credential value
    echo
    echo "Choose input method:"
    echo "1) Type value directly"
    echo "2) Read from file"
    echo "3) Multi-line input"
    read -p "Select method (1-3) [1]: " input_method
    
    case "${input_method:-1}" in
        1)
            read -s -p "Enter credential value (hidden): " cred_value
            echo
            ;;
        2)
            read -p "Enter file path: " file_path
            if [[ ! -f "$file_path" ]]; then
                print_error "File not found: $file_path"
                return 1
            fi
            cred_value=$(cat "$file_path")
            ;;
        3)
            echo "Enter multi-line value (press Ctrl+D when done):"
            cred_value=$(cat)
            ;;
        *)
            print_error "Invalid choice"
            return 1
            ;;
    esac
    
    if [[ -z "$cred_value" ]]; then
        print_error "Credential value cannot be empty"
        return 1
    fi
    
    # Add credential to temp file using Python for safe YAML manipulation
    python3 << EOF
import yaml
import sys

try:
    with open('$TEMP_FILE', 'r') as f:
        data = yaml.safe_load(f)
    
    # Ensure section exists
    if '$section' not in data:
        data['$section'] = {}
    
    # Add/update credential
    data['$section']['$cred_name'] = '''$cred_value'''
    
    with open('$TEMP_FILE', 'w') as f:
        yaml.dump(data, f, default_flow_style=False, allow_unicode=True)
    
    print("Credential added successfully")
except Exception as e:
    print(f"Error: {e}")
    sys.exit(1)
EOF
    
    if [[ $? -eq 0 ]]; then
        print_success "Added credential '$cred_name' to section '$section'"
    else
        print_error "Failed to add credential"
        return 1
    fi
}

# Function to edit vault manually
edit_vault() {
    print_status "Opening vault for manual editing..."
    print_warning "Be careful with YAML syntax! Invalid YAML will cause encryption to fail."
    echo "Press Enter to continue..."
    read
    
    # Use user's preferred editor or default to nano
    editor="${EDITOR:-nano}"
    "$editor" "$TEMP_FILE"
    
    # Validate YAML syntax
    print_status "Validating YAML syntax..."
    if python3 -c "import yaml; yaml.safe_load(open('$TEMP_FILE'))" 2>/dev/null; then
        print_success "YAML syntax is valid"
    else
        print_error "Invalid YAML syntax detected!"
        read -p "Do you want to edit again? (y/N): " edit_again
        if [[ "$edit_again" =~ ^[Yy]$ ]]; then
            edit_vault
            return
        else
            print_error "Aborting due to invalid YAML"
            exit 1
        fi
    fi
}

# Function to show diff of changes
show_diff() {
    print_status "Changes made:"
    echo "----------------------------------------"
    
    # Decrypt original for comparison
    ansible-vault decrypt --vault-password-file "$VAULT_PASS_SCRIPT" --output "credentials_original.yml" "$VAULT_FILE" 2>/dev/null
    
    if command -v diff >/dev/null 2>&1; then
        diff -u "credentials_original.yml" "$TEMP_FILE" | head -50 || true
    else
        print_warning "diff command not available, skipping change preview"
    fi
    
    rm -f "credentials_original.yml"
    echo "----------------------------------------"
}

# Function to encrypt vault
encrypt_vault() {
    print_status "Encrypting vault file..."
    if ansible-vault encrypt --vault-password-file "$VAULT_PASS_SCRIPT" --output "$VAULT_FILE" "$TEMP_FILE"; then
        print_success "Vault encrypted successfully"
    else
        print_error "Failed to encrypt vault"
        # Restore backup
        if [[ -f "$BACKUP_FILE" ]]; then
            cp "$BACKUP_FILE" "$VAULT_FILE"
            print_warning "Restored backup file"
        fi
        exit 1
    fi
}

# Function to commit changes
commit_changes() {
    print_status "Checking git status..."
    
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        print_warning "Not in a git repository, skipping commit"
        return 0
    fi
    
    # Check if vault file has changes
    if ! git diff --quiet "$VAULT_FILE" 2>/dev/null; then
        echo
        read -p "Commit changes to git? (Y/n): " should_commit
        if [[ ! "$should_commit" =~ ^[Nn]$ ]]; then
            read -p "Enter commit message [Update credentials]: " commit_msg
            commit_msg="${commit_msg:-Update credentials}"
            
            git add "$VAULT_FILE"
            git commit -m "$commit_msg

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>"
            
            print_success "Changes committed to git"
        else
            print_status "Skipping git commit"
        fi
    else
        print_status "No changes to commit"
    fi
}

# Main function
main() {
    echo "╭─────────────────────────────────────────────╮"
    echo "│        Secure Credentials Manager           │"
    echo "│     Decrypt → Edit → Encrypt → Commit      │"
    echo "╰─────────────────────────────────────────────╯"
    echo
    
    check_prerequisites
    create_backup
    decrypt_vault
    show_structure
    
    # Main menu loop
    while true; do
        echo
        echo "Choose an action:"
        echo "1) Add new credential"
        echo "2) Edit vault manually"
        echo "3) View current structure"
        echo "4) Finish and encrypt"
        echo "5) Cancel (restore backup)"
        echo
        read -p "Select option (1-5): " action
        
        case "$action" in
            1) add_credential ;;
            2) edit_vault ;;
            3) show_structure ;;
            4) break ;;
            5) 
                print_status "Restoring backup and exiting..."
                cp "$BACKUP_FILE" "$VAULT_FILE"
                exit 0
                ;;
            *) print_error "Invalid option" ;;
        esac
    done
    
    show_diff
    
    read -p "Proceed with encryption? (Y/n): " proceed
    if [[ "$proceed" =~ ^[Nn]$ ]]; then
        print_status "Operation cancelled, restoring backup"
        cp "$BACKUP_FILE" "$VAULT_FILE"
        exit 0
    fi
    
    encrypt_vault
    commit_changes
    
    # Cleanup backup
    read -p "Remove backup file '$BACKUP_FILE'? (Y/n): " remove_backup
    if [[ ! "$remove_backup" =~ ^[Nn]$ ]]; then
        rm -f "$BACKUP_FILE"
        print_success "Backup file removed"
    else
        print_status "Backup kept: $BACKUP_FILE"
    fi
    
    print_success "Credential management completed successfully!"
}

# Run main function
main "$@"