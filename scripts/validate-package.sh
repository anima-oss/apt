#!/usr/bin/env bash
set -Eeuo pipefail

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 package.deb"
    exit 2
fi

PACKAGE="$(realpath "$1")"

[[ -f "$PACKAGE" ]] || {
    echo "ERROR: Package not found: $PACKAGE"
    exit 1
}

[[ "$PACKAGE" == *.deb ]] || {
    echo "ERROR: Expected .deb file."
    exit 1
}

command -v dpkg-deb >/dev/null

CONTROL="$(dpkg-deb --field "$PACKAGE")"

field() {
    awk -v key="$1" '
        BEGIN { FS=": " }
        $1 == key { print substr($0, length(key)+3); exit }
    ' <<< "$CONTROL"
}

NAME="$(field Package)"
VERSION="$(field Version)"
ARCH="$(field Architecture)"
MAINTAINER="$(field Maintainer)"

[[ -n "$NAME" ]] || { echo "ERROR: Missing Package"; exit 1; }
[[ -n "$VERSION" ]] || { echo "ERROR: Missing Version"; exit 1; }
[[ -n "$ARCH" ]] || { echo "ERROR: Missing Architecture"; exit 1; }
[[ -n "$MAINTAINER" ]] || { echo "ERROR: Missing Maintainer"; exit 1; }

if [[ ! "$NAME" =~ ^[a-z0-9][a-z0-9+.-]+$ ]]; then
    echo "ERROR: Invalid Debian package name: $NAME"
    exit 1
fi

case "$ARCH" in
    amd64|all) ;;
    *)
        echo "ERROR: Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

dpkg --compare-versions "$VERSION" gt "0" || {
    echo "ERROR: Invalid package version: $VERSION"
    exit 1
}

dpkg-deb --info "$PACKAGE" >/dev/null

echo "VALID: $NAME"
echo "VERSION: $VERSION"
echo "ARCH: $ARCH"
echo "FILE: $PACKAGE"
