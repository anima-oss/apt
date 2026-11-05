#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEST="$ROOT/packages"

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 package.deb"
    exit 2
fi

PACKAGE="$(realpath "$1")"

"$ROOT/scripts/validate-package.sh" "$PACKAGE"

NAME="$(dpkg-deb -f "$PACKAGE" Package)"
VERSION="$(dpkg-deb -f "$PACKAGE" Version)"
ARCH="$(dpkg-deb -f "$PACKAGE" Architecture)"

mkdir -p "$DEST"

TARGET="$DEST/${NAME}_${VERSION}_${ARCH}.deb"

if [[ -e "$TARGET" ]]; then
    echo "ERROR: Package already exists: $TARGET"
    exit 1
fi

install -m 0644 "$PACKAGE" "$TARGET"

echo "Staged: $TARGET"
