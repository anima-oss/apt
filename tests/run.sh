#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "=========================================="
echo " ANIMA APT AUTOMATED TESTS"
echo "=========================================="

echo "[1/7] Shell and Python syntax"

for file in "$ROOT"/scripts/*.sh "$ROOT"/tests/*.sh; do
    bash -n "$file"
    echo "PASS: $(basename "$file")"
done

python3 - "$ROOT/scripts/download-packages.py" <<'PYTHON'
import ast
import pathlib
import sys

ast.parse(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
print("PASS: download-packages.py syntax")
PYTHON

echo "[2/7] Package catalog"

python3 - "$ROOT/config/packages.yml" <<'PYTHON'
import re
import sys
import yaml

with open(sys.argv[1], encoding="utf-8") as source:
    data = yaml.safe_load(source)

assert data["schema_version"] == 1
packages = data["packages"]
assert isinstance(packages, list) and packages

names = [item["package"] for item in packages]
assert len(names) == len(set(names)), "Duplicate package names"

for item in packages:
    assert re.fullmatch(r"[a-z0-9][a-z0-9+.-]+", item["package"])
    assert re.fullmatch(r"[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+", item["repository"])
    assert item["tag"]
    assert item["asset"].endswith(".deb")
    assert item["architecture"] in ("amd64", "all")
    assert isinstance(item["enabled"], bool)

assert set(names) == {"anima-control", "anima-booter"}
print("PASS: package catalog")
PYTHON

echo "[3/7] Aptly JSON configuration"

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

echo "[4/7] Create a Debian test package"

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

echo "[5/7] Validate Debian package"

"$ROOT/scripts/validate-package.sh" "$TMP/anima-apt-test_1.0.0_amd64.deb"

echo "[6/7] Validate rejection of invalid package"

if "$ROOT/scripts/validate-package.sh" "$ROOT/README.md" >/dev/null 2>&1; then
    echo "FAIL: Invalid file was accepted."
    exit 1
fi

echo "PASS: Invalid package rejected"

echo "[7/7] Verify package metadata"

NAME="$(dpkg-deb -f "$TMP/anima-apt-test_1.0.0_amd64.deb" Package)"
VERSION="$(dpkg-deb -f "$TMP/anima-apt-test_1.0.0_amd64.deb" Version)"
ARCH="$(dpkg-deb -f "$TMP/anima-apt-test_1.0.0_amd64.deb" Architecture)"

[[ "$NAME" == anima-apt-test ]]
[[ "$VERSION" == 1.0.0 ]]
[[ "$ARCH" == amd64 ]]

echo "PASS: Package metadata"
echo
echo "ALL TESTS PASSED"
