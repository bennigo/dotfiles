#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   sway-shortcuts.sh
#     --include-xf86          include XF86 keys
#     --include-bindcode      include bindcode too
#     --desc-required         show only entries that have a smart comment
#     --detail                show an extra dimmed line with the command
#     --with-combos           accepted for compatibility; combos are always shown
#     --debug                 print diagnostics to stderr
#
# Default (compact) view:
#   - Grouped by Category (bold headers)
#   - Lines show: ICON  Description   (dimmed [mode] combo on the right)
#
# Detail view (--detail):
#   - Same first line as compact (ICON + Description + combo)
#   - Second dimmed line underneath with the command text
#   - Selecting either line executes the command

INCLUDE_BINDCODE=0
INCLUDE_XF86=0
DESC_REQUIRED=0
DETAIL_VIEW=0
DEBUG=0

for arg in "$@"; do
  case "$arg" in
  --include-bindcode) INCLUDE_BINDCODE=1 ;;
  --include-xf86) INCLUDE_XF86=1 ;;
  --desc-required) DESC_REQUIRED=1 ;;
  --detail) DETAIL_VIEW=1 ;;
  --with-combos) : ;; # combos are always shown; keep flag for compatibility
  --debug) DEBUG=1 ;;
  *) ;;
  esac
done

user_cfg="${XDG_CONFIG_HOME:-$HOME/.config}/sway/config"

collect_bindings_json() {
  local include_bindcode="${1:-0}"
  local include_xf86="${2:-0}"

  if ! command -v swaymsg >/dev/null 2>&1; then return 1; fi
  if ! swaymsg -r -t get_bindings >/dev/null 2>&1; then return 1; fi
  if ! command -v jq >/dev/null 2>&1; then return 1; fi

  swaymsg -r -t get_bindings | jq --argjson inc_bind "$include_bindcode" --argjson inc_xf86 "$include_xf86" -r '
    .[]
    | select(.input_type=="keyboard")
    # bindsym-only unless include-bindcode:
    | select($inc_bind == 1 or (.symbol != null or ((.key_symbols // []) | length) > 0))
    # exclude XF86 unless included:
    | (if $inc_xf86 == 1 then .
       else
         select(
           ((.symbol // "") | startswith("XF86") | not)
           and
           (((.key_symbols // []) | map(startswith("XF86")) | any) | not)
         )
       end)
    | {
        mode: (if .mode and .mode != "" then .mode else "default" end),
        mods: ((.mods // []) | sort | join("+")),
        key: (
          if .symbol then .symbol
          elif ((.key_symbols // [])|length>0) then .key_symbols[0]
          elif ((.key_codes // [])|length>0) then (.key_codes[0]|tostring)
          else "?"
          end
        ),
        command: .command
      }
    | .mode as $m
    | (.mods as $mods | .key as $key |
       (if $mods == "" then $key else ($mods + "+" + $key) end) ) as $combo
    | [$m, $combo, .command] | @tsv
  '
}

collect_bindings_from_config() {
  local include_bindcode="${1:-0}"
  local include_xf86="${2:-0}"

  local cfg=""
  if command -v swaymsg >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
    cfg="$(swaymsg -r -t get_config | jq -r '.config' 2>/dev/null || true)"
  fi
  if [ -z "${cfg:-}" ] && [ -r "$user_cfg" ]; then
    cfg="$(cat "$user_cfg")"
  fi
  [ -z "${cfg:-}" ] && return 1

  printf "%s\n" "$cfg" | awk -v inc="$include_bindcode" -v incxf="$include_xf86" '
    function trim(s){ gsub(/^[ \t]+|[ \t]+$/,"",s); return s }
    function countc(str, re, tmp) { tmp=str; return gsub(re, "", tmp) }
    function sort_tokens(n, arr, i, j, tmp) { for (i=1;i<=n;i++) for (j=i+1;j<=n;j++) if (arr[j]<arr[i]) { tmp=arr[i]; arr[i]=arr[j]; arr[j]=tmp } }
    function normalize_combo(spec,   tmp, tokc, toks, i, key, mods, mcount) {
      tmp = spec
      for (k in vars) gsub("\\$" k, vars[k], tmp)
      tokc = split(tmp, toks, /\+/)
      if (tokc == 0) return ""
      key = toks[tokc]
      mcount = 0
      for (i=1; i<tokc; i++) if (toks[i] != "") { mcount++; mods[mcount] = toks[i] }
      if (mcount > 1) sort_tokens(mcount, mods)
      if (mcount == 0) return key
      tmp = mods[1]; for (i=2; i<=mcount; i++) tmp = tmp "+" mods[i]
      return tmp "+" key
    }

    BEGIN { current_mode="default"; in_mode=0; waiting_for_open=0; brace_depth=0 }

    { line=$0 }

    (line ~ /^[ \t]*set[ \t]+\$[A-Za-z0-9_]+/) {
      name=$2; sub(/^\$/,"",name)
      val=line; sub(/^[ \t]*set[ \t]+\$[A-Za-z0-9_]+[ \t]+/,"",val); val=trim(val)
      vars[name]=val
      next
    }

    (line ~ /^[ \t]*mode[ \t]+"/) {
      q1=index(line,"\"")
      if (q1>0) { rest=substr(line,q1+1); q2=index(rest,"\""); if (q2>0) {
        current_mode=substr(rest,1,q2-1); in_mode=1
        if (index(line,"{")>0){waiting_for_open=0;brace_depth=1}else{waiting_for_open=1;brace_depth=0}
        next
      } }
    }

    {
      if (in_mode) {
        opens = countc(line, /\{/); closes = countc(line, /\}/)
        if (waiting_for_open) { if (opens>0){ brace_depth=opens; waiting_for_open=0 } }
        else { brace_depth += opens; brace_depth -= closes; if (brace_depth<=0){ in_mode=0; current_mode="default"; waiting_for_open=0; brace_depth=0; next } }
      }
    }

    {
      is_bind = 0
      if (inc) { if (line ~ /^[ \t]*bind(sym|code)[ \t]+/) is_bind=1 }
      else     { if (line ~ /^[ \t]*bindsym[ \t]+/)       is_bind=1 }
      if (!is_bind) next

      l = line
      sub(/[ \t]*#.*/,"",l)
      if (inc) sub(/^[ \t]*bind(sym|code)[ \t]+/, "", l)
      else     sub(/^[ \t]*bindsym[ \t]+/, "", l)
      l = trim(l)
      if (l == "") next

      gsub(/^(--[A-Za-z0-9_-]+[ \t]+)+/,"",l)

      split(l, arr, /[ \t]+/)
      keyspec=arr[1]
      cmd=l; sub(/^[^ \t]+[ \t]+/,"",cmd)

      combo = normalize_combo(keyspec)
      mode  = (current_mode=="" ? "default" : current_mode)

      if (!incxf) { if (combo ~ /(^|[+])XF86/) next }

      print mode "\t" combo "\t" cmd
      next
    }
  '
}

# 2) Build description map from raw source (so comments are preserved)
# Emit: mode\tcombo\tdesc\tcategory\ticon
build_description_map_from_source() {
  if [ ! -r "$user_cfg" ]; then
    [ "$DEBUG" -eq 1 ] && echo "[debug] user config not readable: $user_cfg" >&2
    return 0
  fi

  awk '
    function trim(s){ gsub(/^[ \t]+|[ \t]+$/,"",s); return s }
    function countc(str, re, tmp) { tmp=str; return gsub(re, "", tmp) }
    function sort_tokens(n, arr, i, j, tmp) { for (i=1;i<=n;i++) for (j=i+1;j<=n;j++) if (arr[j]<arr[i]) { tmp=arr[i]; arr[i]=arr[j]; arr[j]=tmp } }
    function normalize_combo(spec,   tmp, tokc, toks, i, key, mods, mcount) {
      tmp = spec
      for (k in vars) gsub("\\$" k, vars[k], tmp)
      tokc = split(tmp, toks, /\+/)
      if (tokc == 0) return ""
      key = toks[tokc]
      mcount = 0
      for (i=1; i<tokc; i++) if (toks[i] != "") { mcount++; mods[mcount] = toks[i] }
      if (mcount > 1) sort_tokens(mcount, mods)
      if (mcount == 0) return key
      tmp = mods[1]; for (i=2; i<=mcount; i++) tmp = tmp "+" mods[i]
      return tmp "+" key
    }

    BEGIN {
      current_mode = "default"
      in_mode = 0
      waiting_for_open = 0
      brace_depth = 0
      pending_desc_line = ""
    }

    { line = $0 }

    (line ~ /^[ \t]*set[ \t]+\$[A-Za-z0-9_]+/) {
      name=$2; sub(/^\$/,"",name)
      val=line; sub(/^[ \t]*set[ \t]+\$[A-Za-z0-9_]+[ \t]+/,"",val); val=trim(val)
      vars[name]=val
      next
    }

    # Capture the entire smart comment line to extract category/desc/icon
    (line ~ /^[ \t]*##.*##[ \t]*$/) {
      pending_desc_line = line
      next
    }

    (line ~ /^[ \t]*mode[ \t]+"/) {
      q1 = index(line, "\"")
      if (q1 > 0) {
        rest = substr(line, q1+1)
        q2 = index(rest, "\"")
        if (q2 > 0) {
          current_mode = substr(rest, 1, q2-1)
          in_mode = 1
          if (index(line, "{") > 0) { waiting_for_open=0; brace_depth=1 }
          else { waiting_for_open=1; brace_depth=0 }
          next
        }
      }
    }

    {
      if (in_mode) {
        opens = countc(line, /\{/); closes = countc(line, /\}/)
        if (waiting_for_open) { if (opens>0) { brace_depth = opens; waiting_for_open = 0 } }
        else {
          brace_depth += opens
          brace_depth -= closes
          if (brace_depth <= 0) {
            in_mode = 0
            current_mode = "default"
            waiting_for_open = 0
            brace_depth = 0
            next
          }
        }
      }
    }

    (line ~ /^[ \t]*bindsym[ \t]+/) {
      original = line

      # Inline smart comment (takes precedence)
      inline_desc_line = ""
      if (original ~ /##.*##/) {
        inline = original
        sub(/^[^#]*##/,"##", inline)
        inline_desc_line = inline
      }

      l = original
      sub(/[ \t]*#.*/,"",l)
      sub(/^[ \t]*bindsym[ \t]+/,"",l)
      l = trim(l)
      if (l == "") { pending_desc_line=""; next }

      gsub(/^(--[A-Za-z0-9_-]+[ \t]+)+/, "", l)

      split(l, arr, /[ \t]+/)
      keyspec = arr[1]
      combo = normalize_combo(keyspec)
      mode  = (current_mode=="" ? "default" : current_mode)

      # Extract category/description/icon from whichever comment is present
      src = (inline_desc_line != "" ? inline_desc_line : pending_desc_line)
      cat = ""; desc=""; icon=""
      if (src != "") {
        t = src
        sub(/^[ \t]*##[ \t]*/, "", t)
        sub(/[ \t]*##[ \t]*$/, "", t)
        n = split(t, parts, /[ \t]*\/\/[ \t]*/)
        if (n >= 1) cat = trim(parts[1])
        if (n >= 2) desc = trim(parts[2])
        if (n >= 3) icon = trim(parts[3])
      }

      if (combo != "") {
        print mode "\t" combo "\t" desc "\t" cat "\t" icon
      }

      pending_desc_line = ""  # consume
      next
    }
  ' "$user_cfg"
}

show_with_terminal() {
  tmp="$(mktemp)"
  cat >"$tmp"
  if command -v foot >/dev/null 2>&1; then
    foot --app-id sway-shortcuts --title "Sway Shortcuts" sh -lc "less -R '$tmp'; rm -f '$tmp'" &
  elif command -v kitty >/dev/null 2>&1; then
    kitty --class sway-shortcuts sh -lc "less -R '$tmp'; rm -f '$tmp'" &
  elif command -v alacritty >/dev/null 2>&1; then
    alacritty --class sway-shortcuts -e sh -lc "less -R '$tmp'; rm -f '$tmp'" &
  else
    xterm -class sway-shortcuts -e sh -lc "less -R '$tmp'; rm -f '$tmp'" &
  fi
}

main() {
  # 1) Description map from source config (keeps comments)
  desc_file="$(mktemp)"
  build_description_map_from_source >"$desc_file" || true
  [ "$DEBUG" -eq 1 ] && echo "[debug] description map lines: $(wc -l <"$desc_file")" >&2

  # 2) Bindings (live if possible)
  binds_file="$(mktemp)"
  if ! collect_bindings_json "$INCLUDE_BINDCODE" "$INCLUDE_XF86" >"$binds_file"; then
    [ "$DEBUG" -eq 1 ] && echo "[debug] falling back to config parsing for bindings" >&2
    if ! collect_bindings_from_config "$INCLUDE_BINDCODE" "$INCLUDE_XF86" >"$binds_file"; then
      echo "No bindings collected."
      exit 1
    fi
  fi
  [ "$DEBUG" -eq 1 ] && echo "[debug] bindings lines: $(wc -l <"$binds_file")" >&2

  # 3) Join: mode|combo -> desc, category, icon
  joined_file="$(mktemp)"
  awk '
    BEGIN { FS="\t"; OFS="\t" }
    # Load desc map
    FNR==NR {
      # desc_file: mode combo desc cat icon
      key = $1 "|" $2
      desc[key] = $3
      cat[key]  = $4
      icon[key] = $5
      next
    }
    # Apply to binds file
    {
      key = $1 "|" $2
      d = (key in desc ? desc[key] : "")
      c = (key in cat  ? cat[key]  : "")
      i = (key in icon ? icon[key] : "")
      print c, d, i, $1, $2, $3
    }
  ' "$desc_file" "$binds_file" >"$joined_file"

  # 4) Optionally require descriptions
  if [ "$DESC_REQUIRED" -eq 1 ]; then
    tmpf="$(mktemp)"
    awk 'BEGIN{FS=OFS="\t"} length($2)>0' "$joined_file" >"$tmpf"
    mv "$tmpf" "$joined_file"
  fi

  # 5) Sort by Category then Description (case-insensitive)
  TAB="$(printf '\t')"
  sorted_file="$(mktemp)"
  LC_ALL=C sort -f -t "$TAB" -k1,1 -k2,2 "$joined_file" >"$sorted_file"

  # 6) Build display and action map in one awk pass
  display_file="$(mktemp)"
  actions_file="$(mktemp)"
  awk -v FS="\t" -v detail="$DETAIL_VIEW" -v disp_out="$display_file" -v map_out="$actions_file" '
    function esc(s,  t) { t=s; gsub(/&/, "\\&amp;", t); gsub(/</, "\\&lt;", t); gsub(/>/, "\\&gt;", t); return t }
    function map_mod(m) {
      mlow = m; gsub(/^[[:space:]]+|[[:space:]]+$/, "", mlow); mlow = tolower(mlow)
      if (mlow=="mod1") return "Alt"
      if (mlow=="mod2") return "NumLock"
      if (mlow=="mod3") return "Mod3"
      if (mlow=="mod4") return "Super"
      if (mlow=="mod5") return "AltGr"
      if (mlow=="control" || mlow=="ctrl") return "Ctrl"
      if (mlow=="shift") return "Shift"
      if (mlow=="alt") return "Alt"
      if (mlow=="super") return "Super"
      if (mlow=="meta") return "Meta"
      return m
    }
    function prettify_combo(combo,   n, a, i, mods, mc, key, out) {
      if (combo == "") return combo
      n = split(combo, a, /\+/)
      if (n == 1) return a[1]
      mc = 0
      for (i=1; i<n; i++) { mods[++mc] = map_mod(a[i]) }
      key = a[n]
      out = mods[1]
      for (i=2; i<=mc; i++) out = out "+" mods[i]
      return out "+" key
    }
    BEGIN { current_cat = ""; first_item = 1 }
    {
      cat  = $1; desc = $2; icon = $3; mode = $4; combo = $5; cmd = $6
      if (cat == "") cat = "Other"
      if (current_cat != cat) {
        if (!first_item) {
          print "" > disp_out
          print "NOP" > map_out
        }
        print "<b>" esc(cat) "</b>" > disp_out
        print "NOP" > map_out
        if (detail) {
          print "<span alpha=\"35%\">────────────────────────────────</span>" > disp_out
          print "NOP" > map_out
        }
        current_cat = cat
        first_item = 0
      }
      shown = (length(desc)>0 ? desc : cmd)
      icon_show = (icon=="" ? "•" : icon)
      combo_pretty = prettify_combo(combo)
      combo_str = (mode=="default" ? combo_pretty : "[" mode "] " combo_pretty)

      # First line: icon + desc + (combo)
      line = "  " icon_show "  " esc(shown)
      if (combo_str != "") {
        line = line "  <span alpha=\"50%\">(" esc(combo_str) ")</span>"
      }
      print line > disp_out
      print "RUN\t" cmd > map_out

      # Detail line: command (dimmed)
      if (detail) {
        print "      <span alpha=\"60%\">" esc(cmd) "</span>" > disp_out
        print "RUN\t" cmd > map_out
      }
    }
  ' "$sorted_file"

  # 7) Rofi: capture selected index and run corresponding command (if any)
  if command -v rofi >/dev/null 2>&1; then
    sel_index="$(
      rofi -dmenu -i -markup-rows -matching fuzzy -normal-window \
        -window-title "Sway Shortcuts" -p "Sway Shortcuts" -no-fixed-num-lines \
        -format i \
        -theme-str "window { width: 1000px; height: 650px; } listview { lines: 35; }" \
        <"$display_file"
    )"
    if [ -z "${sel_index:-}" ]; then
      exit 0
    fi
    # sed is 1-based, rofi index is 0-based
    map_line="$(sed -n "$((sel_index + 1))p" "$actions_file" || true)"
    if [ -n "$map_line" ]; then
      action="$(printf '%s\n' "$map_line" | cut -f1)"
      cmd="$(printf '%s\n' "$map_line" | cut -f2-)"
      if [ "$action" = "RUN" ] && [ -n "$cmd" ]; then
        if command -v swaymsg >/dev/null 2>&1; then
          swaymsg -q exec -- "$cmd" >/dev/null 2>&1 || true
        else
          sh -lc "$cmd" >/dev/null 2>&1 || true
        fi
      fi
    fi
  fi

  if ! command -v rofi >/dev/null 2>&1; then
    cat "$display_file" | show_with_terminal
  fi
}

main
