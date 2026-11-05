#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "=========================================="
echo " ANIMA APT AUTOMATED TESTS"
echo "=========================================="

echo "[1/6] Shell syntax"

for file in "$ROOT"/scripts/*.sh "$ROOT"/tests/*.sh; do
    bash -n "$file"
    echo "PASS: $(basename "$file")"
done

echo "[2/6] Aptly JSON configuration"

python3 - "$ROOT/config/aptly.conf.example" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as f:
    data = json.load(f)

assert data["architectures"] == ["amd64", "all"]
assert data["gpgDisableSign"] is False
assert "public" in data["FileSystemPublishEndpoints"]
print("PASS: Aptly JSON configuration")
PY

echo "[3/6] Create a Debian test package"

mkdir -p "$TMP/pkg/DEBIAN"

cat > "$TMP/pkg/DEBIAN/control" <<'CONTROL'
Package: anima-apt-test
Version: 1.0.0
Section: utils
Priority: optional
Architecture: amd64
Maintainer: Anima OSS <packages@anima-oss.org>
Description: Temporary package used to test Anima APT infrastructure.
CONTROL

dpkg-deb --build "$TMP/pkg" "$TMP/anima-apt-test_1.0.0_amd64.deb" >/dev/null

echo "PASS: Test .deb created"

echo "[4/6] Validate Debian package"

"$ROOT/scripts/validate-package.sh" "$TMP/anima-apt-test_1.0.0_amd64.deb"

echo "[5/6] Validate rejection of invalid package"

if "$ROOT/scripts/validate-package.sh" "$ROOT/README.md" >/dev/null 2>&1; then
    echo "FAIL: Invalid file was accepted."
    exit 1
fi

echo "PASS: Invalid package rejected"

echo "[6/6] Verify package metadata"

NAME="$(dpkg-deb -f "$TMP/anima-apt-test_1.0.0_amd64.deb" Package)"
VERSION="$(dpkg-deb -f "$TMP/anima-apt-test_1.0.0_amd64.deb" Version)"
ARCH="$(dpkg-deb -f "$TMP/anima-apt-test_1.0.0_amd64.deb" Architecture)"

[[ "$NAME" == anima-apt-test ]]
[[ "$VERSION" == 1.0.0 ]]
[[ "$ARCH" == amd64 ]]

echo "PASS: Package metadata"
echo
echo "ALL TESTS PASSED"
