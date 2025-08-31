#!/bin/bash

# commit-credentials.sh - Simple script to commit credential vault changes
# This script checks for changes and commits them with a proper message

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
VAULT_FILE="credentials.vault"

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

# Function to check if we're in a git repository
check_git_repo() {
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        print_error "Not in a git repository"
        exit 1
    fi
}

# Function to check if vault file exists
check_vault_file() {
    if [[ ! -f "$VAULT_FILE" ]]; then
        print_error "Vault file '$VAULT_FILE' not found. Are you in the system/ directory?"
        exit 1
    fi
}

# Function to show vault file status
show_status() {
    print_status "Checking credential vault status..."
    
    # Check if file is tracked
    if ! git ls-files --error-unmatch "$VAULT_FILE" >/dev/null 2>&1; then
        print_warning "Vault file is not tracked by git yet"
        return 1
    fi
    
    # Check if there are changes
    if git diff --quiet "$VAULT_FILE" 2>/dev/null; then
        print_status "No changes detected in vault file"
        return 2
    fi
    
    print_status "Changes detected in vault file"
    return 0
}

# Function to show diff if requested
show_diff() {
    if [[ "$1" == "--show-diff" ]]; then
        print_status "Changes in vault file:"
        echo "----------------------------------------"
        # Show file status change only (can't show actual diff of encrypted file)
        git diff --stat "$VAULT_FILE" || true
        echo "----------------------------------------"
        print_warning "Note: Cannot show actual content diff (file is encrypted)"
    fi
}

# Function to commit changes
commit_vault() {
    local commit_message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Default commit message if none provided
    if [[ -z "$commit_message" ]]; then
        commit_message="Update credentials vault"
    fi
    
    # Add vault file to staging
    print_status "Adding vault file to git staging..."
    git add "$VAULT_FILE"
    
    # Commit with message
    print_status "Committing changes..."
    git commit -m "$commit_message

Updated: $timestamp

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>"
    
    print_success "Credentials vault committed successfully"
    
    # Show commit info
    local commit_hash=$(git rev-parse --short HEAD)
    print_status "Commit: $commit_hash"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS] [COMMIT_MESSAGE]"
    echo
    echo "Options:"
    echo "  --show-diff    Show file changes before committing"
    echo "  --help         Show this help message"
    echo
    echo "Examples:"
    echo "  $0                                    # Commit with default message"
    echo "  $0 \"Add new API keys\"               # Commit with custom message"
    echo "  $0 --show-diff \"Update database credentials\""
    echo
    echo "This script commits changes to the encrypted credentials vault file."
    echo "It automatically adds the vault file to git staging and creates a"
    echo "commit with a descriptive message including timestamp."
}

# Main function
main() {
    local show_diff_flag=false
    local commit_message=""
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --show-diff)
                show_diff_flag=true
                shift
                ;;
            --help|-h)
                show_usage
                exit 0
                ;;
            *)
                commit_message="$1"
                shift
                ;;
        esac
    done
    
    echo "╭─────────────────────────────────────────────╮"
    echo "│         Credentials Vault Committer        │"
    echo "╰─────────────────────────────────────────────╯"
    echo
    
    # Check prerequisites
    check_git_repo
    check_vault_file
    
    # Check status
    show_status
    status_result=$?
    
    case $status_result in
        1) # File not tracked
            read -p "Vault file is not tracked. Add to git? (Y/n): " should_add
            if [[ ! "$should_add" =~ ^[Nn]$ ]]; then
                commit_vault "${commit_message:-Add encrypted credentials vault}"
            else
                print_status "Operation cancelled"
                exit 0
            fi
            ;;
        2) # No changes
            print_status "Nothing to commit"
            exit 0
            ;;
        0) # Has changes
            if $show_diff_flag; then
                show_diff --show-diff
                echo
            fi
            
            # Get commit message if not provided
            if [[ -z "$commit_message" ]]; then
                read -p "Enter commit message [Update credentials vault]: " commit_message
                commit_message="${commit_message:-Update credentials vault}"
            fi
            
            # Confirm commit
            read -p "Commit vault changes with message '$commit_message'? (Y/n): " should_commit
            if [[ ! "$should_commit" =~ ^[Nn]$ ]]; then
                commit_vault "$commit_message"
            else
                print_status "Operation cancelled"
                exit 0
            fi
            ;;
    esac
}

# Run main function with all arguments
main "$@"