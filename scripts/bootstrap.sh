#!/usr/bin/env bash
set -Eeuo pipefail

MISSING=()

for command in aptly dpkg-deb dpkg gpg gpgv curl git; do
    if ! command -v "$command" >/dev/null 2>&1; then
        MISSING+=("$command")
    fi
done

if ((${#MISSING[@]})); then
    echo "Missing commands: ${MISSING[*]}"
    echo
    echo "Install basic dependencies:"
    echo "sudo apt update"
    echo "sudo apt install -y gnupg curl dpkg-dev"
    echo
    echo "Install Aptly using:"
    echo "https://www.aptly.info/download/"
    exit 1
fi

echo "All dependencies available."
aptly version
gpg --version | head -n 1
dpkg-deb --version | head -n 1
