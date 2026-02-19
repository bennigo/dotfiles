# Neovim Configuration - LazyVim-based IDE

This file provides context for Claude Code when working with this Neovim configuration.

## Overview

**Editor**: Neovim v0.11.4 (built from source, RelWithDebInfo)
**Foundation**: LazyVim with extensive customization
**Multi-language**: Python, R, LaTeX, Lua, Markdown, C/C++
**Key Integrations**: Claude Code, PostgreSQL Database UI, Obsidian, R Statistical Computing

This is a production IDE for scientific computing (GPS/GNSS data processing), knowledge management (Obsidian), and multi-language development.

## Critical Integrations

### Claude Code (AI Pair Programming - Primary)

**File**: `lua/plugins/claude-code.lua`
**Primary Keymap**: `<M-c>` (toggle/focus)
**Leader Mappings**: `<leader>aci` (toggle), `<leader>acc` (focus), `<leader>acs` (send), `<leader>acd/D` (accept/reject diff)

**Configuration**:
- Floating window: 95% width, 95% height
- Diff: vertical split, keeps terminal focus
- Auto-close diffs on accept
- WebSocket connection to Claude Code CLI
- Transparency enabled (winblend: 30)

### Avante (Secondary AI - Local + ACP)

**File**: `lua/plugins/avante.lua`
**Primary Keymap**: `<M-C>` (Zen mode - full screen)
**Leader Mappings**: `<leader>aa` (ask), `<leader>ae` (edit), `<leader>as` (sidebar), `<leader>ap*` (providers)

**Features**:
- **Mode**: Agentic (tool execution enabled)
- **Default Provider**: Ollama (llama3.1:8b) - free, local
- **ACP Provider**: Claude Code (`<leader>apc`) - uses your Claude Max subscription via CLI
- **Project Instructions**: Create `avante.md` in project root for context
- **Token Counting**: Enabled in UI

**Provider Switching**:
- `<leader>apo`: Use Ollama (local, free)
- `<leader>apc`: Use Claude Code (via ACP - leverages Claude Max subscription)

**Also Available**: Codeium and Copilot (disabled by default)

### CodeCompanion (Evaluation Alternative)

**File**: `lua/plugins/codecompanion.lua`
**Status**: Evaluation alongside Avante (1-2 week trial)
**Leader Mappings**: `<leader>C*` (non-conflicting with Avante)

**Philosophy**: "Like Zed AI" - chat + quick inline edits with deep Neovim integration
- Better maintained (1 open issue vs Avante's 203)
- Deep LSP/buffer integration via variables (`#buffer`, `#lsp`)
- Slash commands for context injection (`/buffer`, `/file`, `/help`)

**Key Commands**:
- `<leader>Cc`: Toggle chat window
- `<leader>Ci`: Inline edit (quick changes in buffer)
- `<leader>Cp`: Action palette (all available actions)
- `<leader>Ce/f/t`: Explain/Fix/Test code (visual mode)

**Evaluation Criteria**:
- Compare stability with Avante
- Test LSP diagnostics sharing
- Assess diff application reliability
- Evaluate overall workflow fit

### Database UI (PostgreSQL Integration)

**File**: `lua/plugins/extend-dadbod.lua`
**Primary Keymap**: `<leader>D` (toggle DBUI)

**Features**:
- Full PostgreSQL 18 integration
- Connections via `~/.pgpass` (managed by `pass`)
- Saved queries in `~/.config/nvim/db_ui/`
- SQL completion via vim-dadbod-completion
- Auto-execute table helpers enabled

**Cross-Reference**: See `~/.dotfiles/ansible/DATABASE_SETUP.md` for credential setup

### Obsidian (Knowledge Management)

**File**: `lua/plugins/obsidian.lua`
**Vault**: `~/notes/bgovault/`
**Organization**: PARA method (Projects, Areas, Resources, Archives)

**Features**:
- Daily notes: `Journal/daily/` with template
- Inbox: `0.Inbox/` for new notes
- Completion: via blink.cmp
- Zettelkasten-style note IDs (timestamp + title)
- Daily note format: workdays only

**Cross-Reference**: See `~/notes/bgovault/CLAUDE.md` for vault-specific context

### R Statistical Computing

**File**: `lua/plugins/extend-R.lua`
**Plugins**: R.nvim, cmp-r, neotest-testthat

**Features**:
- Full IDE for R
- REPL integration
- R completion engine
- Test runner via neotest
- Plot support

### LaTeX (Academic Writing)

**Plugin**: vimtex
**Integration**: TeX Live with Icelandic language support

**Features**:
- Compilation and preview
- Icelandic hyphenation
- PDF viewer integration

## Architecture

### LazyVim Foundation

This configuration extends LazyVim rather than replacing it:
- LazyVim provides sensible defaults
- Custom plugins in `lua/plugins/`
- Extensions use `opts` function pattern
- Never modify LazyVim core files

### Plugin Organization Pattern

**Naming Convention**:
- `extend-*.lua`: Extensions/overrides of LazyVim defaults
- `[name].lua`: Standalone plugin configurations
- `disabled.lua`: Disabled LazyVim default plugins

**Examples**:
- `extend-ai.lua`: Adds Claude Code to LazyVim AI ecosystem
- `extend-dadbod.lua`: Database UI configuration
- `obsidian.lua`: Standalone Obsidian integration

### Configuration Layers

1. **Core Config** (`lua/config/`)
   - `options.lua`: Editor settings (spell check, line numbers, etc.)
   - `keymaps.lua`: Global keymaps
   - `lazy.lua`: Plugin manager setup
   - `autocmds.lua`: Auto commands

2. **Plugin Configs** (`lua/plugins/`)
   - Individual plugin configurations
   - LazyVim extensions
   - Custom integrations

3. **Filetype Configs** (`ftplugin/`)
   - Language-specific settings

4. **Lock File** (`lazy-lock.json`)
   - Plugin version pins
   - Updated on :Lazy sync

## Plugin Ecosystem

### AI & Completion (8 plugins)

- **claudecode.nvim**: Claude Code integration - primary AI (claude-code.lua)
- **avante.nvim**: Secondary AI with Ollama + ACP support (avante.lua)
- **codecompanion.nvim**: Evaluation alternative - "Zed AI" style (codecompanion.lua)
- **blink.cmp**: Modern completion engine (fast, async)
- **blink.compat**: Compatibility layer for cmp sources
- **copilot.lua**: GitHub Copilot (disabled)
- **codeium.nvim**: Codeium AI assistant (disabled)
- **lazydev.nvim**: Lua LSP enhancement for Neovim development

### Database & Data (3 plugins)

- **vim-dadbod-ui**: Database UI (extend-dadbod.lua)
- **vim-dadbod**: Database interaction core
- **vim-dadbod-completion**: SQL completion

### File Navigation & Search (4 plugins)

- **fzf-lua**: Fuzzy finder (extend-fzf.lua) - fast, flexible
- **harpoon**: Quick file bookmarking (extend-harpoon.lua)
- **mini.files**: Modern file browser (extend-mini-files.lua)
- **neo-tree.nvim**: Traditional file tree explorer

### Markdown & Documentation (5 plugins)

- **obsidian.nvim**: Obsidian vault integration (obsidian.lua)
- **render-markdown.nvim**: Rich inline markdown rendering (extend-rendermarkdown.lua)
- **bullets.vim**: Smart bullet list handling (markdown-bullets.lua)
- **markdown-preview.nvim**: Live browser preview
- **ltex_extra.nvim**: Grammar/spell checking for markdown

### Language Support (7 plugins)

- **R.nvim**: R statistical computing IDE (extend-R.lua)
- **vimtex**: Comprehensive LaTeX support
- **nvim-lspconfig**: LSP configurations
- **nvim-treesitter**: Advanced syntax highlighting
- **nvim-treesitter-textobjects**: Smart text objects
- **nvim-treesitter-context**: Sticky context header
- **clangd_extensions.nvim**: Enhanced C/C++ features

### Testing (3 plugins)

- **neotest**: Universal testing framework
- **neotest-python**: Python test runner (pytest)
- **neotest-testthat**: R test runner (testthat)

### UI & Aesthetics (8 plugins)

- **catppuccin**: Primary color scheme (colorscheme.lua) - with transparency toggle
- **tokyonight.nvim**: Alternative theme
- **gruvbox.nvim**: Alternative theme
- **lualine.nvim**: Status line
- **bufferline.nvim**: Buffer tabs
- **noice.nvim**: Enhanced UI (messages, cmdline, popups)
- **mini.icons**: Icon support
- **nvim-web-devicons**: File type icons

### Code Editing (9 plugins)

- **flash.nvim**: Enhanced motion (jump anywhere)
- **mini.surround**: Surround text operations (quotes, brackets)
- **mini.ai**: Enhanced text objects
- **mini.pairs**: Auto-pairs (brackets, quotes)
- **dial.nvim**: Enhanced increment/decrement (dates, booleans, etc.)
- **inc-rename.nvim**: LSP rename with preview
- **nvim-ts-autotag**: Auto-close HTML/JSX tags
- **yanky.nvim**: Enhanced yank/paste
- **grug-far.nvim**: Search and replace

### Development Tools (10 plugins)

- **mason.nvim**: LSP/tool installer
- **mason-lspconfig.nvim**: Mason-LSP bridge
- **conform.nvim**: Code formatting (black, ruff, prettier, etc.)
- **nvim-lint**: Linting engine
- **trouble.nvim**: Diagnostics list (extend-trouble.lua)
- **todo-comments.nvim**: TODO/FIXME highlighting
- **gitsigns.nvim**: Git integration (hunks, blame)
- **guess-indent.nvim**: Auto-detect indentation
- **ts-comments.nvim**: Smart comments
- **venv-selector.nvim**: Python virtual env selector

### Utility (7 plugins)

- **snacks.nvim**: UI components library (extend-snacks.lua)
- **which-key.nvim**: Keymap hints and documentation (extend-which-key.lua)
- **toggleterm.nvim**: Terminal management (toggle_term.lua)
- **persistence.nvim**: Session management
- **plenary.nvim**: Lua utility library (dependency)
- **nui.nvim**: UI component library (dependency)
- **nvim-nio**: Async IO library (dependency)

### Snippets & Templates (2 plugins)

- **LuaSnip**: Snippet engine (extend-luasnip.lua)
- **friendly-snippets**: Snippet collection

### Special Purpose (3 plugins)

- **vim-kitty**: Kitty terminal integration
- **SchemaStore.nvim**: JSON schema support
- **cmake-tools.nvim**: CMake integration

## Custom Keymaps & Workflows

### Project-Specific File Finders

**GPS Library Work**:
- `<leader>fL`: Find files in GPS library (`~/work/projects/gps/gpslibrary_new/`)
- `<leader>sL`: Grep GPS library files

**Dotfiles**:
- `<leader>fd`: Find dotfiles (searches `~/.dotfiles/`, `~/.config/`, `~/.local/`)
- `<leader>so`: Grep dotfiles

**General Work**:
- `<leader>fw`: Find work files (`~/work/`)
- `<leader>sO`: Grep work files (`~/work/`, `~/work/projects/`)

### Custom Toggles & UI

- `<leader>uo`: Toggle transparency (Catppuccin theme)
- `<leader>uN`: Toggle Noice UI (enhanced messages)
- `<M-m>`: Float terminal (works in normal and terminal mode)
- `<M-c>`: Toggle Claude Code
- `<M-tab>`: Switch to alternate buffer
- `<M-q>`: Delete buffer

### Modified LazyVim Defaults

**Window Management** (freed `<leader>w` for save):
- `<leader>w`: Save file (was window commands)
- `<leader>Wd`: Delete window (moved from `<leader>wd`)
- `<leader>Wm`: Zoom window toggle (moved from `<leader>wm`)

**Increment/Decrement** (tmux conflict):
- `<C-s>`: Increment (tmux uses `<C-a>`)
- `<C-x>`: Decrement

**Save Shortcuts**:
- `<M-w>`: Save file (works in all modes)
- `<leader>w`: Save file (normal mode)

### Enhanced Navigation

- `<C-d>`, `<C-u>`: Half-page scroll centered (zz)
- `n`, `N`: Search next/prev centered (zz)
- `*`, `#`, `g*`, `g#`: Search word under cursor centered (zz)
- `J`: Join lines preserving cursor position

### Mermaid Diagram Workflow

**Keymap**: `<leader>mp` (Mermaid Preview)

**Workflow**:
1. Edit `.mmd` file in Neovim
2. Press `<leader>mp`
3. Auto-generates PDF (if needed) using mmdc
4. Opens in Zathura PDF viewer (detached process)

**Requirements**: mmdc (mermaid-cli), zathura, `~/.config/mermaid-puppeteer.json`

### Quick Editing

- `jk`: Exit insert/visual mode (`<ESC>` alternative)
- `<leader>r`: Replace word under cursor (interactive)
- `<leader>X`: Make current file executable (`chmod +x`)
- `<leader><CR>`: Source current file (`:so %`)

### Clipboard Operations

- `<leader>y`: Yank to system clipboard
- `<leader>Y`: Yank line to system clipboard
- `<leader>d`: Delete to black hole register (no yank)
- `p` (in visual): Paste without yanking replaced text

## Language-Specific Features

### Python

**LSP**: pyright (via mason)
**Formatting**: black, ruff (via conform.nvim)
**Linting**: ruff (via nvim-lint)
**Testing**: neotest-python (pytest integration)
**Virtual Env**: venv-selector.nvim

**Type Hints**: Required for projects (mypy compatibility)

### R

**IDE**: R.nvim (full REPL integration)
**Completion**: cmp-r
**Testing**: neotest-testthat
**Features**: Plot support, object inspection, help system

**Workflow**: Scientific computing, statistical analysis

### LaTeX

**Plugin**: vimtex
**Compilation**: Automatic on save (optional)
**Preview**: PDF viewer integration
**Language**: Icelandic + English support

### Markdown

**Rendering**: render-markdown.nvim (inline)
**Bullets**: bullets.vim (smart lists)
**Preview**: markdown-preview.nvim (browser)
**Integration**: Obsidian.nvim for vault files
**Diagrams**: Mermaid support via custom workflow

### Lua

**LSP**: lua-language-server (via mason)
**Completion**: lazydev.nvim (Neovim API aware)
**Formatting**: stylua (via conform.nvim)

**Special**: Neovim config development optimized

### C/C++

**LSP**: clangd
**Extensions**: clangd_extensions.nvim
**Build**: cmake-tools.nvim

## Editor Settings

### Spell Checking

**Enabled**: Yes (by default)
**Languages**: Icelandic (is), American English (en_us)
**Setting**: `vim.opt.spelllang = "is,en_us"`

**Use Case**: Mixed Icelandic/English documentation and domain terms

### Visual Settings

- **Line Numbers**: Relative + absolute hybrid
- **Scroll Offset**: 20 lines (always show context)
- **Side Scroll**: 8 characters
- **Color Column**: 80 (visual line length guide)
- **Cursor Line**: Enabled
- **Terminal Colors**: Enabled (termguicolors)

### Indentation

**Auto-Detection**: guess-indent.nvim
**Respects**: .editorconfig, project conventions
**Default**: Varies by filetype

### Search

**Incremental**: Yes
**Highlight**: Managed per-session
**Case**: Smart case (lowercase = insensitive)

## File Structure Reference

```
.config/nvim/
├── init.lua                           # Entry point
├── lua/
│   ├── config/
│   │   ├── lazy.lua                  # LazyVim setup
│   │   ├── options.lua               # Editor options
│   │   ├── keymaps.lua               # Global keymaps
│   │   └── autocmds.lua              # Auto commands
│   └── plugins/
│       ├── avante.lua                # Avante AI (Ollama + ACP)
│       ├── claude-code.lua           # Claude Code integration
│       ├── codecompanion.lua         # CodeCompanion (evaluation)
│       ├── extend-dadbod.lua         # Database UI
│       ├── extend-fzf.lua            # Fuzzy finder config
│       ├── extend-harpoon.lua        # File bookmarks
│       ├── extend-lspconfig.lua      # LSP overrides
│       ├── extend-luasnip.lua        # Snippets config
│       ├── extend-mini-files.lua     # File browser
│       ├── extend-R.lua              # R IDE config
│       ├── extend-rendermarkdown.lua # Markdown rendering
│       ├── extend-snacks.lua         # UI components
│       ├── extend-telescope.lua      # (legacy, using fzf now)
│       ├── extend-treesitter.lua     # Treesitter config
│       ├── extend-trouble.lua        # Diagnostics
│       ├── extend-ui.lua             # UI tweaks
│       ├── extend-which-key.lua      # Keymap help
│       ├── extend-windows.lua        # Window management
│       ├── obsidian.lua              # Obsidian vault
│       ├── colorscheme.lua           # Theme config
│       ├── codeium.lua               # Codeium AI
│       ├── disabled.lua              # Disabled plugins
│       ├── floaterminal.lua          # Terminal config
│       ├── guess-indent.lua          # Indent detection
│       ├── image.lua                 # Image support
│       ├── languages.lua             # Language configs
│       ├── markdown-bullets.lua      # Bullet lists
│       ├── mason-workaround.lua      # Mason fixes
│       ├── toggle_term.lua           # Terminal toggle
│       └── example.lua               # LazyVim examples
├── lazy-lock.json                     # Plugin version lock file
├── lazyvim.json                       # LazyVim config
├── db_ui/                             # Database UI saved queries
├── ftplugin/                          # Filetype-specific configs
├── spell/                             # Spell dictionaries
├── test_stuff/                        # Testing area
└── .neoconf.json                      # Project-local LSP config
```

## Development Guidelines

### Adding New Plugins

1. **Create Config File**:
   ```lua
   -- lua/plugins/my-plugin.lua
   return {
     "author/plugin-name",
     event = "VeryLazy",  -- or other lazy-loading trigger
     config = function()
       require("plugin-name").setup({
         -- configuration here
       })
     end,
   }
   ```

2. **For LazyVim Extensions** (use extend-* pattern):
   ```lua
   -- lua/plugins/extend-something.lua
   return {
     "LazyVim/plugin-name",
     opts = function(_, opts)
       -- Modify opts table
       return opts
     end,
   }
   ```

3. **Install**: Run `:Lazy sync`

4. **Document**: Update this CLAUDE.md file

### Modifying LazyVim Defaults

**Never**: Edit LazyVim core files
**Always**: Override in `lua/plugins/extend-*.lua`

**Pattern**:
```lua
return {
  "original/plugin",
  opts = function(_, opts)
    -- opts contains LazyVim defaults
    -- modify and return
    opts.new_option = "value"
    return opts
  end,
}
```

### Custom Keymaps

**Global Keymaps**: Add to `lua/config/keymaps.lua`
**Plugin Keymaps**: Add to plugin config file
**Documentation**: Update `extend-which-key.lua` for discoverability

**Conventions**:
- `<leader>`: Commands and actions
- `<M-key>`: Toggles and quick access (Alt/Meta)
- `<C-key>`: Editor operations (Ctrl)

### Removing Plugins

**LazyVim Default**: Add to `disabled.lua`
```lua
return {
  { "plugin/name", enabled = false },
}
```

**Custom Plugin**: Delete config file, run `:Lazy clean`

**Always**: Update this CLAUDE.md

### Testing Changes

1. **Syntax Check**: Source file with `<leader><CR>` (`:so %`)
2. **Plugin Sync**: `:Lazy sync`
3. **LSP Check**: `:LspInfo`, `:Mason`
4. **Health Check**: `:checkhealth`
5. **Full Test**: Restart Neovim

## Installation & Build

**Method**: Built from source via Ansible
**Role**: `development` (see `~/.dotfiles/ansible/roles/development/tasks/main.yml`)
**Source Directory**: `~/Downloads/git/neovim`
**Branch**: stable
**Build Type**: RelWithDebInfo
**Install Location**: `/usr/local/bin/nvim`

**Dependencies Installed**:
- Build essentials (cmake, ninja, gettext, etc.)
- Tree-sitter CLI (via npm)
- LSP servers (via Mason in Neovim)
- pynvim (Python provider)

**Deployment**: Stow-managed from `~/.dotfiles/neovim/`

## Common Operations

### Plugin Management

```vim
:Lazy                  " Open plugin manager
:Lazy sync             " Update and install plugins
:Lazy clean            " Remove unused plugins
:Lazy profile          " Profile startup time
```

### LSP Operations

```vim
:LspInfo               " LSP client status
:Mason                 " Open Mason installer
:MasonUpdate           " Update Mason registry
```

### Database Operations

```vim
:DBUI                  " Toggle database UI
:DBUIToggle            " Same as above
<leader>D              " Keymap for DBUI toggle
```

### Obsidian Operations

**Command format**: `legacy_commands = false` — use space-separated format, NOT PascalCase.

```vim
" New format (correct):
:Obsidian today          " Open today's daily note
:Obsidian new            " Create new note
:Obsidian search         " Search vault
:Obsidian quick_switch   " Quick note switcher
:Obsidian backlinks      " Show backlinks
:Obsidian tags           " Search tags
:Obsidian template       " Insert from template
:Obsidian rename         " Rename note
:Obsidian paste_img      " Paste image

" OLD format (will NOT work):
" :ObsidianToday, :ObsidianNew, :ObsidianQuickSwitch, etc.
```

**API notes** (obsidian.nvim v3.15+):
- Actions moved: `require("obsidian").actions.toggle_checkbox()` (was `util.toggle_checkbox`)
- Actions moved: `require("obsidian").actions.smart_action()` (was `util.smart_action`)
- Global state: Use `Obsidian.opts`, `Obsidian.workspace` (not `client.opts`, `client.dir`)
- Callbacks: No longer receive `client` as first argument — `client` is deprecated, will be removed in 4.0.0

### Testing

```vim
:Neotest               " Open test UI
:Neotest run           " Run nearest test
:Neotest summary       " Show test summary
```

### Health Checks

```vim
:checkhealth           " Full health check
:checkhealth nvim      " Neovim core health
:checkhealth lsp       " LSP health
```

## Cross-References

- **Main Dotfiles**: `~/.dotfiles/CLAUDE.md` - Overall system context
- **Ansible Development**: `~/.dotfiles/ansible/roles/development/` - Build/install procedures
- **Database Setup**: `~/.dotfiles/ansible/DATABASE_SETUP.md` - PostgreSQL credential management
- **System Config**: `~/.dotfiles/system/CLAUDE.md` - Hardware and system-level configs
- **Obsidian Vault**: `~/notes/bgovault/CLAUDE.md` - Knowledge management context
- **LazyVim Docs**: https://lazyvim.github.io/ - Official LazyVim documentation

## Important Notes

### Configuration Management

**Source**: `~/.dotfiles/neovim/.config/nvim/` (Stow source)
**Deployed**: `~/.config/nvim/` (symlinked)
**Edit**: Always edit source files in dotfiles repo, not deployed location

### Database Integration

**Connections**: Managed via `~/.pgpass`
**Credential Source**: GPG-encrypted `pass` store (`~/.password-store/`)
**Update Script**: `update-pgpass` (regenerates `.pgpass` from pass)
**PostgreSQL Version**: 18

See: `~/.dotfiles/ansible/DATABASE_SETUP.md`

### Obsidian Integration

**Vault**: `~/notes/bgovault/` (PARA organization)
**Auto-Sync**: Not configured (manual git workflow)
**Daily Notes**: Workdays only, with template
**New Notes**: Go to `0.Inbox/` by default

### Spell Checking

**Languages**: Icelandic (is) + American English (en_us)
**Context**: Scientific work with Icelandic domain terms, personal projects in Icelandic
**Custom Dictionary**: `spell/` directory for project-specific terms

### Mermaid Diagrams

**Files**: `.mmd` extension
**Compilation**: mmdc (mermaid-cli via npm)
**Config**: `~/.config/mermaid-puppeteer.json`
**Viewer**: Zathura (PDF)
**Keymap**: `<leader>mp`

### Performance

**Startup Time**: ~50-80ms (lazy loading enabled)
**Plugin Count**: 75+ plugins (most lazy-loaded)
**LSP Servers**: Installed on-demand via Mason
**Optimization**: Disabled unused LazyVim defaults in `disabled.lua`

---

**Created**: 2025-10-05
**Neovim Version**: v0.11.4 (built from source)
**Base Framework**: LazyVim
**Primary Use Cases**: Scientific computing (GPS/GNSS), Knowledge management (Obsidian), Multi-language development
**Context Level**: Plugin-specific guidance for Neovim configuration