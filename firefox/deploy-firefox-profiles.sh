#!/usr/bin/env bash
# deploy-firefox-profiles.sh — Create Firefox profiles and deploy user.js settings
#
# Run this on a fresh laptop after installing Firefox (snap).
# After deployment, launch each profile and sign in to Firefox Sync
# to restore passwords, bookmarks, and extensions.
#
# Usage: deploy-firefox-profiles.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROFILES_DIR="${SCRIPT_DIR}/profiles"

# Snap Firefox profile root
FF_ROOT="${HOME}/snap/firefox/common/.mozilla/firefox"
PROFILES_INI="${FF_ROOT}/profiles.ini"

# Profiles to create (not including default which already exists)
NEW_PROFILES=("work" "personal")

# All profiles that get a user.js deployed
ALL_PROFILES=("default" "work" "personal")

for PROFILE in "${NEW_PROFILES[@]}"; do
    # Check if profile already exists in profiles.ini
    if grep -q "Name=${PROFILE}" "${PROFILES_INI}" 2>/dev/null; then
        echo "Profile '${PROFILE}' already exists"
    else
        echo "Creating profile '${PROFILE}'..."
        firefox --no-remote -CreateProfile "${PROFILE}" 2>/dev/null
    fi
done

for PROFILE in "${ALL_PROFILES[@]}"; do
    USER_JS="${PROFILES_DIR}/${PROFILE}.user.js"

    if [[ ! -f "${USER_JS}" ]]; then
        echo "WARNING: No user.js for '${PROFILE}', skipping" >&2
        continue
    fi

    # Find the profile directory path from profiles.ini
    PROFILE_PATH=$(awk -v name="${PROFILE}" '
        /^\[Profile/ { section=1; path="" }
        section && /^Name=/ { if ($0 == "Name=" name) found=1 }
        section && /^Path=/ { path=substr($0, 6) }
        found && path { print path; exit }
    ' "${PROFILES_INI}")

    if [[ -z "${PROFILE_PATH}" ]]; then
        echo "WARNING: Could not find profile path for '${PROFILE}', skipping" >&2
        continue
    fi

    FULL_PATH="${FF_ROOT}/${PROFILE_PATH}"
    echo "Deploying user.js to ${FULL_PATH}"
    cp "${USER_JS}" "${FULL_PATH}/user.js"
done

echo ""
echo "Done. Next steps:"
echo "  1. Launch profiles:  firefox-profile work"
echo "                       firefox-profile personal"
echo "  2. Sign in to Firefox Sync in each profile"
echo "  3. Pinned tabs and tab groups will need to be set up manually"
