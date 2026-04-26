#!/usr/bin/env bash
# tmux-shortcuts.sh — Browse tmux key bindings from annotated config files.
# Reads  ## Category // Description // Icon ##  comments (inline or line-before).

set -euo pipefail

CONF_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/tmux"
CONFIGS=("$CONF_DIR/tmux.reset.conf" "$CONF_DIR/tmux.conf")

# ── Detect prefix key ──────────────────────────────────────────────────────────
PREFIX="C-b"
for f in "${CONFIGS[@]}"; do
  [[ -r "$f" ]] || continue
  p=$(grep -E '^set(-option)?[[:space:]]+-g[[:space:]]+prefix[[:space:]]' "$f" 2>/dev/null \
      | awk '{print $NF}' | tail -1 || true)
  [[ -n "$p" ]] && PREFIX="$p"
done

# ── Detect plugin-set bindings (@plugin-name-bind 'key') ───────────────────────
plugin_bind() {
  grep -h "@$1 " "${CONFIGS[@]}" 2>/dev/null \
    | awk '{print $NF}' | tr -d "'" | tail -1 || true
}
FLOAX_BIND=$(plugin_bind "floax-bind")
FLOAX_MENU=$(plugin_bind "floax-bind-menu")
SESSIONX_BIND=$(plugin_bind "sessionx-bind")

# ── Parse annotated bind-key lines ────────────────────────────────────────────
parse_annotated() {
  awk -v PREFIX="$PREFIX" '
    function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }

    BEGIN { pending = "" }

    # Line-before comment:  # ## Category // Description // Icon ##
    /^[ \t]*#[ \t]*##.*\/\/.*##/ {
      t = $0
      sub(/^[^#]*#[ \t]*##[ \t]*/, "", t)
      sub(/[ \t]*##[[:space:]]*$/, "", t)
      pending = trim(t)
      next
    }

    # bind-key / bind lines (single-line; multi-line bindings need line-before comment)
    /^[ \t]*(bind-key|bind)[ \t]/ {
      comment = ""
      line = $0

      # Inline  ## Category // Description // Icon ##  takes precedence
      if (match(line, /##[^#]+##/)) {
        t = substr(line, RSTART + 2, RLENGTH - 4)
        comment = trim(t)
      } else if (pending != "") {
        comment = pending
      }
      pending = ""
      if (comment == "") next

      n = split(comment, parts, /\/\//)
      cat  = (n >= 1 ? trim(parts[1]) : "Other")
      desc = (n >= 2 ? trim(parts[2]) : "")
      icon = (n >= 3 ? trim(parts[3]) : "•")
      if (icon == "") icon = "•"
      if (desc == "") { desc = cat; cat = "Other" }

      # Extract key — strip flags first
      l = line
      sub(/^[ \t]*(bind-key|bind)[ \t]+/, "", l)
      sub(/[ \t]#.*$/, "", l)
      l = trim(l)

      no_prefix = 0; table = ""
      while (1) {
        if      (l ~ /^-r[ \t]/) { sub(/^-r[ \t]+/, "", l); l = trim(l) }
        else if (l ~ /^-n[ \t]/) { no_prefix = 1; sub(/^-n[ \t]+/, "", l); l = trim(l) }
        else if (l ~ /^-T[ \t]/) {
          sub(/^-T[ \t]+/, "", l); l = trim(l)
          split(l, ta, /[ \t]+/); table = ta[1]
          sub(/^[^ \t]+[ \t]+/, "", l); l = trim(l)
        }
        else break
      }
      split(l, ka, /[ \t]+/)
      key = ka[1]

      if      (no_prefix || table == "root")     combo = key " (always active)"
      else if (table == "" || table == "prefix") combo = PREFIX " + " key
      else                                        combo = key " [" table "]"

      print cat "\t" icon "\t" desc "\t" combo
      next
    }

    # Non-comment, non-empty lines clear pending (no bind-key match)
    !/^[ \t]*#/ && !/^$/ { pending = "" }
  ' "${CONFIGS[@]}"
}

# ── Combine parsed + plugin-detected bindings and sort ─────────────────────────
build_rows() {
  {
    parse_annotated
    [[ -n "$FLOAX_BIND"    ]] && printf 'Panes\t🪟\tToggle floating pane\t%s + %s\n'            "$PREFIX" "$FLOAX_BIND"
    [[ -n "$FLOAX_MENU"    ]] && printf 'Panes\t📋\tFloating pane menu\t%s + %s\n'              "$PREFIX" "$FLOAX_MENU"
    [[ -n "$SESSIONX_BIND" ]] && printf 'Session\t🔍\tSession picker (zoxide + fzf)\t%s + %s\n' "$PREFIX" "$SESSIONX_BIND"
  } | LC_ALL=C sort -t$'\t' -k1,1 -k3,3
}

main() {
  if command -v fzf >/dev/null 2>&1; then
    build_rows | awk '
      BEGIN { FS = "\t" }
      { printf "\033[2m[%-10s]\033[0m  %s  \033[0;36m%-34s\033[0m  \033[2m%s\033[0m\n",
          $1, $2, $3, $4 }
    ' | fzf \
        --ansi --no-sort --reverse \
        --header=" Tmux Shortcuts   prefix: $PREFIX   —   type to filter" \
        --header-first \
        --prompt="  " \
        --height=100% \
        --border=rounded \
        --margin=1,2 \
        --padding=1 \
        --color='header:bold,header:blue,prompt:cyan,pointer:cyan' \
        || true
  else
    build_rows | awk '
      BEGIN { FS = "\t"; cur = ""; first = 1 }
      {
        if ($1 != cur) {
          if (!first) printf "\n"
          printf "\033[1;34m── %s ──\033[0m\n", $1
          cur = $1; first = 0
        }
        printf "  %s  \033[0;36m%-34s\033[0m  \033[2m%s\033[0m\n", $2, $3, $4
      }
    ' | less -R
  fi
}

main
