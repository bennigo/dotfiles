#!/bin/bash
# Fuzzy search integration for NeoMutt + Obsidian email system

OBSIDIAN_VAULT="/home/bgo/notes/bgovault"
EMAIL_FOLDER="$OBSIDIAN_VAULT/2.Areas/Email"

# Function to search Obsidian email notes
search_obsidian_emails() {
    echo "🔍 Searching Obsidian email notes..."
    
    if command -v fzf >/dev/null 2>&1; then
        # Use fzf for fuzzy search
        find "$EMAIL_FOLDER" -name "*.md" -type f 2>/dev/null | \
        while read -r file; do
            # Extract metadata for preview
            subject=$(grep "^subject:" "$file" | cut -d'"' -f2)
            from=$(grep "^from:" "$file" | cut -d'"' -f2)
            date=$(grep "^date:" "$file" | cut -d'"' -f2)
            echo "$file|$subject|$from|$date"
        done | \
        fzf --delimiter='|' \
            --with-nth=2,3,4 \
            --preview='echo "Subject: {2}"; echo "From: {3}"; echo "Date: {4}"; echo ""; head -20 {1}' \
            --preview-window=up:50% \
            --header="Obsidian Email Search - Enter to open in editor" | \
        cut -d'|' -f1 | \
        while read -r selected_file; do
            if [[ -n "$selected_file" ]]; then
                "${EDITOR:-nvim}" "$selected_file"
            fi
        done
    else
        # Fallback to grep-based search
        echo "Enter search term:"
        read -r search_term
        grep -r -i "$search_term" "$EMAIL_FOLDER" --include="*.md" -l | head -10
    fi
}

# Function to search current NeoMutt mailbox with notmuch
search_current_mailbox() {
    echo "🔍 Searching current mailbox..."
    
    if command -v notmuch >/dev/null 2>&1; then
        echo "Enter search query (notmuch syntax):"
        read -r query
        notmuch search "$query" | head -20
    else
        echo "Notmuch not available. Install with: sudo apt install notmuch"
    fi
}

# Function to create quick email note
quick_note() {
    local subject="$1"
    local content="$2"
    
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local filename="${timestamp}_quick_note.md"
    
    cat > "$EMAIL_FOLDER/$filename" << EOF
---
type: email_note
source: manual
subject: "$subject"
created: $(date -Iseconds)
tags: [email, note, quick]
---

# Quick Email Note: $subject

## Content

$content

## Actions

- [ ] Process and categorize
- [ ] Create related tasks if needed

## Links

<!-- Link to related emails, projects, or areas -->

EOF
    
    echo "Created quick note: $EMAIL_FOLDER/$filename"
    "${EDITOR:-nvim}" "$EMAIL_FOLDER/$filename"
}

# Main menu
case "$1" in
    "search")
        search_obsidian_emails
        ;;
    "mailbox")
        search_current_mailbox
        ;;
    "note")
        quick_note "$2" "$3"
        ;;
    "stats")
        echo "📊 Email System Statistics"
        echo ""
        echo "Obsidian Email Notes:"
        find "$EMAIL_FOLDER" -name "*.md" -type f 2>/dev/null | wc -l
        echo ""
        echo "Recent imports (last 7 days):"
        find "$EMAIL_FOLDER" -name "*.md" -type f -mtime -7 2>/dev/null | wc -l
        echo ""
        echo "Email folder size:"
        du -sh "$EMAIL_FOLDER" 2>/dev/null || echo "0 KB"
        ;;
    *)
        echo "🔍 NeoMutt + Obsidian Email Search System"
        echo ""
        echo "Usage: $0 <command> [options]"
        echo ""
        echo "Commands:"
        echo "  search                   - Fuzzy search through Obsidian email notes"
        echo "  mailbox                  - Search current mailbox with notmuch"
        echo "  note <subject> <content> - Create quick email note"
        echo "  stats                    - Show email system statistics"
        echo ""
        echo "NeoMutt Integration:"
        echo "  - Press 'O' on any email to export to Obsidian"
        echo "  - Press 'Ctrl+O' to show recent imports"
        echo "  - Use this script for searching imported emails"
        echo ""
        echo "Dependencies:"
        echo "  - fzf (for fuzzy search): sudo apt install fzf"
        echo "  - notmuch (for mailbox search): sudo apt install notmuch"
        ;;
esac