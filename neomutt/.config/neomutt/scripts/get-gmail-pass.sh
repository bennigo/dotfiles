#!/bin/bash
export GPG_TTY=$(tty 2>/dev/null || echo "/dev/tty")
/usr/bin/pass email/bgovedur@gmail.com | head -n1
