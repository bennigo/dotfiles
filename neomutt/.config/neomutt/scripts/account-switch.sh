#!/bin/bash
# NeoMutt Account Switcher
# Usage: account-switch.sh [gmail|benedikt|afreksnefnd]

ACCOUNT="$1"
CONFIG_DIR="$HOME/.config/neomutt"

case "$ACCOUNT" in
    "gmail"|"g")
        echo "source $CONFIG_DIR/accounts/gmail" > $CONFIG_DIR/current-account
        echo "Switched to: bgovedur@gmail.com"
        ;;
    "benedikt"|"b"|"klifur")
        echo "source $CONFIG_DIR/accounts/benedikt-klifursamband" > $CONFIG_DIR/current-account
        echo "Switched to: benedikt@klifursamband.is"
        ;;
    "afreksnefnd"|"a"|"af")
        echo "source $CONFIG_DIR/accounts/afreksnefnd-klifursamband" > $CONFIG_DIR/current-account
        echo "Switched to: afreksnefnd@klifursamband.is"
        ;;
    "list"|"")
        echo "Available accounts:"
        echo "  gmail (g)        - bgovedur@gmail.com"
        echo "  benedikt (b)     - benedikt@klifursamband.is"
        echo "  afreksnefnd (a)  - afreksnefnd@klifursamband.is"
        echo
        echo "Usage: account-switch.sh [account-name]"
        ;;
    *)
        echo "Unknown account: $ACCOUNT"
        echo "Use 'account-switch.sh list' to see available accounts"
        exit 1
        ;;
esac