#!/bin/bash
# Email to Obsidian integration script
# Converts selected emails to Obsidian notes with proper metadata

OBSIDIAN_VAULT="/home/bgo/notes/bgovault"
EMAIL_FOLDER="$OBSIDIAN_VAULT/2.Areas/Email"
EMAIL_ASSETS_FOLDER="$OBSIDIAN_VAULT/Assets/email_attachments"
TEMPLATE_PATH="$OBSIDIAN_VAULT/Templates/Email.md"

# Create folders if they don't exist
mkdir -p "$EMAIL_FOLDER"
mkdir -p "$EMAIL_ASSETS_FOLDER"

# Function to sanitize filename (only for filename, not content)
sanitize_filename() {
    echo "$1" | sed 's/^Subject: //g' | sed 's/[^a-zA-Z0-9áéíóúýþðæöÁÉÍÓÚÝÞÐÆÖ \-_.]/_/g' | sed 's/ /_/g' | sed 's/__*/_/g'
}

# Function to decode MIME encoded headers
decode_mime_header() {
    local encoded="$1"
    # Handle MIME encoded headers and decode quoted-printable
    local decoded=$(echo "$encoded" | sed -E 's/=\?[^?]+\?[QqBb]\?([^?]+)\?=/\1/g')
    # Decode common Icelandic characters from quoted-printable
    decoded=$(echo "$decoded" | sed 's/=C1/Á/g; s/=C9/É/g; s/=CD/Í/g; s/=D3/Ó/g; s/=DA/Ú/g; s/=DD/Ý/g; s/=DE/Þ/g; s/=D0/Ð/g; s/=C6/Æ/g; s/=D6/Ö/g')
    decoded=$(echo "$decoded" | sed 's/=E1/á/g; s/=E9/é/g; s/=ED/í/g; s/=F3/ó/g; s/=FA/ú/g; s/=FD/ý/g; s/=FE/þ/g; s/=F0/ð/g; s/=E6/æ/g; s/=F6/ö/g')
    # Convert underscores back to spaces in quoted-printable headers
    decoded=$(echo "$decoded" | sed 's/_/ /g')
    echo "$decoded"
}

# Function to extract plain text from multipart email
extract_plain_text() {
    local email_file="$1"
    local body_start=$(grep -n "^$" "$email_file" | head -1 | cut -d: -f1)
    
    if [[ -n "$body_start" ]]; then
        # Get the full body
        local full_body=$(tail -n +$((body_start + 1)) "$email_file")
        
        # Try to find plain text part
        local plain_text=""
        
        # Look for Content-Type: text/plain
        if echo "$full_body" | grep -q "Content-Type: text/plain"; then
            # Extract content between text/plain marker and next boundary, preserving empty lines
            plain_text=$(echo "$full_body" | awk '
                /Content-Type: text\/plain/ { in_plain=1; next }
                /^$/ && in_plain==1 { in_plain=2; next }
                /^--/ && in_plain==2 { exit }
                in_plain==2 { print }
            ')
        fi
        
        # If no plain text found, get first part after headers
        if [[ -z "$plain_text" ]]; then
            plain_text=$(echo "$full_body" | awk '/^$/{flag=1; next} flag && /^--/{exit} flag')
        fi
        
        # Clean up quoted-printable encoding while preserving empty lines
        echo "$plain_text" | \
        # Remove Content- lines first
        grep -v "^Content-" | \
        # Remove Windows carriage returns
        tr -d '\r' | \
        # Handle quoted-printable soft line breaks line by line to preserve empty lines
        awk '
        {
            # If line ends with = (soft break), remove = and continue to next line without newline
            if (/=$/) {
                gsub(/=$/, "")
                printf "%s", $0
            } else {
                # Normal line, print with newline
                print $0
            }
        }' | \
        # Decode Icelandic characters
        sed 's/=C1/Á/g; s/=C9/É/g; s/=CD/Í/g; s/=D3/Ó/g; s/=DA/Ú/g; s/=DD/Ý/g; s/=DE/Þ/g; s/=D0/Ð/g; s/=C6/Æ/g; s/=D6/Ö/g' | \
        sed 's/=E1/á/g; s/=E9/é/g; s/=ED/í/g; s/=F3/ó/g; s/=FA/ú/g; s/=FD/ý/g; s/=FE/þ/g; s/=F0/ð/g; s/=E6/æ/g; s/=F6/ö/g' | \
        # Convert underscores to spaces
        sed 's/_/ /g' | \
        # Add two spaces at end of non-empty lines for markdown line breaks, preserve empty lines exactly
        sed '/^[[:space:]]*$/{s/.*//; p; d;}; s/$/  /'
    fi
}

# Function to extract and save email attachments (images and files)
extract_attachments() {
    local email_file="$1"
    local timestamp="$2"
    
    # Simple approach - just look for image references and try to extract base64 data
    # This is much more reliable than complex AWK parsing
    grep -n "Content-Type: image" "$email_file" | while IFS=':' read -r line_num rest; do
        # line_num is now clean without the colon
        
        # Look for Content-ID in the next few lines
        content_id=$(sed -n "$((line_num+1)),$((line_num+5))p" "$email_file" | grep "Content-ID:" | head -1 | sed 's/Content-ID: <//; s/>$//')
        
        if [[ -n "$content_id" ]]; then
            # Extract image type from the rest of the line
            img_type=$(echo "Content-Type: image$rest" | sed 's/.*Content-Type: image\///; s/[;,].*//')
            
            # Create filename
            img_name=$(echo "$content_id" | sed 's/@.*//')
            safe_fname="${timestamp}_${img_name}.${img_type}"
            local_path="$EMAIL_ASSETS_FOLDER/$safe_fname"
            
            # Find the start of base64 data (after empty line following headers)
            data_start=$(sed -n "$((line_num+1)),\$p" "$email_file" | grep -n "^$" | head -1 | cut -d: -f1)
            if [[ -n "$data_start" ]]; then
                actual_line=$((line_num + data_start))
                
                # Extract base64 data until boundary
                sed -n "$((actual_line+1)),\$p" "$email_file" | sed '/^--/q' | head -n -1 > "/tmp/img_data_$$"
                
                # Try to decode as base64
                if base64 -d "/tmp/img_data_$$" > "$local_path" 2>/dev/null; then
                    if [[ -s "$local_path" ]]; then
                        echo "$content_id:$safe_fname"
                    fi
                fi
                rm -f "/tmp/img_data_$$"
            fi
        fi
    done
}

# Function to extract email metadata
extract_email() {
    local email_file="$1"
    local output_dir="$2"
    
    # Extract and decode headers (handle multi-line headers)
    local subject_raw=$(awk '/^Subject:/{sub(/^Subject: /, ""); subject=$0; next} /^[[:space:]]/{if(subject) subject=subject $0; next} /^[^[:space:]]/{if(subject) {print subject; exit}}' "$email_file")
    local from_raw=$(grep "^From:" "$email_file" | sed 's/From: //' | head -1)
    local date=$(grep "^Date:" "$email_file" | sed 's/Date: //' | head -1)
    local to=$(grep "^To:" "$email_file" | sed 's/To: //' | head -1)
    local message_id=$(grep "^Message-ID:" "$email_file" | sed 's/Message-ID: //' | head -1)
    
    # If subject is still empty, try a simpler approach
    if [[ -z "$subject_raw" ]]; then
        subject_raw=$(grep "^Subject:" "$email_file" | sed 's/Subject: //' | head -1)
    fi
    
    # Decode MIME encoded headers
    local subject=$(decode_mime_header "$subject_raw")
    local from=$(decode_mime_header "$from_raw")
    
    # Clean subject - remove "Subject: " prefix if present and decode properly
    subject=$(echo "$subject" | sed 's/^Subject: //g')
    
    # Create safe filename
    local safe_subject=$(sanitize_filename "$subject")
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local filename="${timestamp}_${safe_subject:0:50}.md"
    
    # Extract clean email body and preserve formatting
    local body=$(extract_plain_text "$email_file")
    
    # Extract attachments (images and files) and get mappings
    local attachment_mappings=$(extract_attachments "$email_file" "$timestamp")
    
    # Replace attachment references in body
    if [[ -n "$attachment_mappings" ]]; then
        while IFS=':' read -r cid fname; do
            if [[ -n "$cid" && -n "$fname" ]]; then
                body=$(echo "$body" | sed "s|\[cid:$cid\]|![[Assets/email_attachments/$fname]]|g")
            fi
        done <<< "$attachment_mappings"
    fi
    
    # Create clean Obsidian note with vault-compatible frontmatter
    cat > "$output_dir/$filename" << EOF
---
tags: [type/email]
subject: "$subject"
from: "$from"
date: "$date"
created: $(date -Iseconds)
area: ""
project: ""
resource: ""
---

# $subject

**From:** $from  
**Date:** $date  

$body

EOF
    
    echo "Created: $output_dir/$filename"
    echo "$output_dir/$filename"  # Return path for further processing
}

# Main execution
case "$1" in
    "import")
        if [[ -z "$2" ]]; then
            echo "Usage: $0 import <email_file> [output_dir]"
            exit 1
        fi
        
        email_file="$2"
        output_dir="${3:-$EMAIL_FOLDER}"
        
        # Handle stdin input from NeoMutt pipe
        if [[ "$email_file" == "/dev/stdin" ]]; then
            temp_file="/tmp/neomutt_email_$$.tmp"
            cat > "$temp_file"
            email_file="$temp_file"
            cleanup_temp=true
        fi
        
        if [[ ! -f "$email_file" ]]; then
            echo "Error: Email file '$email_file' not found"
            exit 1
        fi
        
        extract_email "$email_file" "$output_dir"
        
        # Cleanup temporary file if created
        if [[ "$cleanup_temp" == "true" && -f "$temp_file" ]]; then
            rm "$temp_file"
        fi
        ;;
        
    "setup")
        # Create email template if it doesn't exist
        mkdir -p "$(dirname "$TEMPLATE_PATH")"
        if [[ ! -f "$TEMPLATE_PATH" ]]; then
            cat > "$TEMPLATE_PATH" << 'EOF'
---
type: email
source: neomutt
subject: "{{subject}}"
from: "{{from}}"
to: "{{to}}"
date: "{{date}}"
message_id: "{{message_id}}"
imported: "{{date:YYYY-MM-DDTHH:mm:ssZ}}"
tags: [email, inbox]
---

# Email: {{subject}}

## Metadata
- **From:** {{from}}  
- **To:** {{to}}  
- **Date:** {{date}}  
- **Account:** {{account_name}}

## Content

```
{{content}}
```

## Notes

<!-- Add your notes and thoughts here -->

## Actions

- [ ] Review and categorize
- [ ] Create follow-up tasks if needed
- [ ] Archive when processed

## Links

<!-- Link to related projects, people, or areas -->
EOF
        fi
        
        echo "Setup complete!"
        echo "Email folder: $EMAIL_FOLDER"
        echo "Template: $TEMPLATE_PATH"
        ;;
        
    "inbox")
        # Show recent email imports
        find "$EMAIL_FOLDER" -name "*.md" -mtime -7 -exec ls -la {} \; | head -10
        ;;
        
    "debug")
        if [[ -z "$2" ]]; then
            echo "Usage: $0 debug <email_file>"
            exit 1
        fi
        
        email_file="$2"
        
        # Handle stdin input from NeoMutt pipe
        if [[ "$email_file" == "/dev/stdin" ]]; then
            temp_file="/tmp/neomutt_debug_$$.tmp"
            cat > "$temp_file"
            email_file="$temp_file"
            cleanup_temp=true
        fi
        
        echo "=== DEBUG: Raw email body start ==="
        body_start=$(grep -n "^$" "$email_file" | head -1 | cut -d: -f1)
        if [[ -n "$body_start" ]]; then
            tail -n +$((body_start + 1)) "$email_file" | head -50
        fi
        echo "=== DEBUG: Raw email body end ==="
        
        echo ""
        echo "=== DEBUG: Extracted plain text ==="
        extract_plain_text "$email_file" | head -50
        echo "=== DEBUG: Plain text end ==="
        
        # Cleanup
        if [[ "$cleanup_temp" == "true" && -f "$temp_file" ]]; then
            rm "$temp_file"
        fi
        ;;
        
    *)
        echo "NeoMutt to Obsidian Email Integration"
        echo ""
        echo "Usage: $0 <command> [options]"
        echo ""
        echo "Commands:"
        echo "  setup                    - Initialize email integration"
        echo "  import <file> [dir]      - Import email file to Obsidian"
        echo "  inbox                    - Show recent email imports"
        echo "  debug <file>             - Debug email parsing (shows raw vs processed)"
        echo ""
        echo "Integration with NeoMutt:"
        echo "  1. In NeoMutt, select email and press 'o' (pipe to command)"
        echo "  2. Enter: $0 import /tmp/email.txt"
        echo "  3. Email will be imported to Obsidian vault"
        ;;
esac