# herdr pane resume hint — which conversation did THIS pane hold? --------------
#
# Agent panes come back after a reboot as plain shells in their cwds
# ([session] resume_agents_on_restore = false in ~/.config/herdr/config.toml), so
# you choose what to reopen — but with ~11 shells there is no way to tell which
# conversation lived where. herdr records the session identity per pane; this
# prints the exact resume command inside the pane it belongs to.
#
# The script self-gates three ways, so this stays cheap and quiet:
#   * no-op unless $HERDR_ENV is set (i.e. we are in a herdr pane)
#   * silent when the pane has no recorded conversation and no pi/claude session
#     for its cwd
#   * printed at most once per boot per pane (marker keyed on boot_id), so
#     nested subshells do not reprint it
#
# Re-show it any time with: herdr-pane-resume-hint --force
# Inspect every pane with:   herdr-pane-resume-hint --all
#
# See local_bin/.local/bin/herdr-pane-resume-hint. Sibling tool `herdr-resume-hints`
# renders the same information from a snapshot taken at shutdown (systemd
# ExecStop), which survives a lost session.json.

# Uses `command -v` rather than the fork-free zsh `$+commands[...]` form on
# purpose: shellcheck lints this file as bash and splits that subscript on the
# hyphens into five bogus SC2154s. Matches the style already in .zshrc.
if [[ -n ${HERDR_ENV:-} ]] && command -v herdr-pane-resume-hint &>/dev/null; then
    herdr-pane-resume-hint
fi
