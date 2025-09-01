# NeoMutt + Obsidian Hybrid Email System

## Overview

A powerful integration between NeoMutt (terminal email client) and Obsidian (knowledge management) that provides:

- **Vim-like email navigation** with multi-account switching
- **Selective email import** to Obsidian for knowledge management
- **Fuzzy search** through imported emails
- **Structured note-taking** with email metadata
- **PARA method integration** (Projects, Areas, Resources, Archive)

## Account Switching

| Keybinding | Action |
|------------|--------|
| `Alt+1` | Switch to Gmail |
| `Alt+2` | Switch to Benedikt@klifursamband.is |
| `Alt+3` | Switch to Afreksnefnd@klifursamband.is |

## Obsidian Integration Keybindings

| Keybinding | Action |
|------------|--------|
| `O` | Export current email to Obsidian |
| `Ctrl+O` | Show recent Obsidian imports |
| `/` | Fuzzy search through Obsidian emails |
| `Ctrl+S` | Show email system statistics |

## Workflow

### 1. Browse Emails in NeoMutt
- Use vim-like navigation (`j/k`, `gg/G`, `d/u`)
- Switch between accounts as needed
- Use built-in search (`/`) for current mailbox

### 2. Selective Import to Obsidian
- Press `O` on any important email to export it
- Email is converted to structured Obsidian note with:
  - Full metadata (from, to, date, subject)
  - Original content preserved
  - Action items template
  - Tags for organization

### 3. Knowledge Management in Obsidian
- Imported emails appear in `2.Areas/Email/`
- Add your own notes, thoughts, and links
- Connect emails to projects, people, and areas
- Create follow-up tasks and actions

### 4. Search and Retrieval
- Press `/` in NeoMutt for fuzzy search of imported emails
- Use Obsidian's full-text search across all notes
- Cross-reference emails with other knowledge

## File Structure

```
bgovault/
├── 2.Areas/Email/           # Imported emails
├── Templates/Email.md       # Email note template
└── [your existing PARA structure]
```

## Email Note Format

Each imported email becomes a structured note:

```markdown
---
type: email
source: neomutt
subject: "Email subject"
from: "sender@example.com"
to: "you@example.com"
date: "Thu, 01 Sep 2025 07:00:00 +0000"
message_id: "<unique-id@server.com>"
imported: "2025-09-01T07:00:00Z"
tags: [email, inbox]
---

# Email: Subject Line

## Metadata
- **From:** sender@example.com
- **To:** you@example.com  
- **Date:** Thu, 01 Sep 2025 07:00:00 +0000
- **Account:** account_name

## Content
[Original email content]

## Notes
[Your thoughts and analysis]

## Actions
- [ ] Review and categorize
- [ ] Create follow-up tasks if needed
- [ ] Archive when processed

## Links
[Links to related projects, people, areas]
```

## Advanced Usage

### Batch Operations
- Search in NeoMutt, then export multiple important emails
- Use Obsidian's tag system to organize by priority/type
- Create MOCs (Maps of Content) for email threads

### Integration with PARA
- Link emails to specific projects in `1.Projects/`
- Reference people and organizations in `3.Resources/`
- Archive processed emails to `4.Archive/`

### Automation Opportunities
- Set up rules to auto-tag emails by sender/subject
- Create templates for common email types
- Use Obsidian plugins for additional functionality

## Dependencies

### Required
- NeoMutt (installed via Ansible)
- Obsidian vault at `/home/bgo/notes/bgovault`

### Recommended
- `fzf` for fuzzy search: `sudo apt install fzf`
- `notmuch` for advanced search: `sudo apt install notmuch`

## Troubleshooting

### Email not importing
- Check permissions on scripts: `ls -la ~/.config/neomutt/scripts/`
- Verify Obsidian vault path exists
- Check email folder: `ls -la ~/notes/bgovault/2.Areas/Email/`

### Search not working
- Install fzf: `sudo apt install fzf`
- Check script permissions: `chmod +x ~/.config/neomutt/scripts/email-search.sh`

### Account switching issues
- Verify App Passwords are current
- Check network connectivity
- Review debug logs: `tail -f ~/.cache/neomutt/debug*`

## Goals Achieved

✅ **Local copy of all emails** - Available offline in both NeoMutt and Obsidian  
✅ **Vim-speed navigation** - Full keyboard control with vim-like bindings  
✅ **Fuzzy searching** - Both in NeoMutt and across Obsidian notes  
✅ **Claude AI integration** - Ready for AI-assisted email organization and analysis

This hybrid system combines the speed and efficiency of terminal email with the power of modern knowledge management, creating a unique productivity workflow tailored to your needs.