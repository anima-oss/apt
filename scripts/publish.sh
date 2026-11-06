#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

PACKAGES_DIR="${1:-$ROOT/packages}"
PUBLIC_DIR="${2:-$ROOT/public}"

CODENAME="${APT_CODENAME:-trixie}"
COMPONENT="${APT_COMPONENT:-main}"
ARCHITECTURE="${APT_ARCHITECTURE:-amd64}"
REPO_NAME="${APT_REPO_NAME:-anima-oss}"
SNAPSHOT="${APT_SNAPSHOT_NAME:-anima-oss-$(date -u +%Y%m%d%H%M%S)-$$}"

CONFIG="$ROOT/config/aptly.conf"
if [[ ! -f "$CONFIG" ]]; then
    CONFIG="$ROOT/config/aptly.conf.example"
fi

[[ -f "$CONFIG" ]] || {
    echo "ERROR: Aptly configuration not found." >&2
    exit 1
}
APTLY_ROOT="${APTLY_ROOT_DIR:-$ROOT/.aptly}"

die() {
    echo "ERROR: $*" >&2
    exit 1
}

command -v aptly >/dev/null || die "Aptly is not installed."
command -v gpg >/dev/null || die "GPG is not installed."
command -v dpkg-deb >/dev/null || die "dpkg-deb is not installed."

[[ -d "$PACKAGES_DIR" ]] || die "Package directory not found."
[[ -n "${APT_GPG_KEY_ID:-}" ]] || die "APT_GPG_KEY_ID is required."
[[ -n "$CODENAME" && -n "$COMPONENT" ]] || die "Invalid distribution configuration."

mkdir -p "$PACKAGES_DIR" "$PUBLIC_DIR" "$APTLY_ROOT"

mapfile -d '' DEBS < <(
    find "$PACKAGES_DIR" -type f -name '*.deb' -print0 | sort -z
)

((${#DEBS[@]} > 0)) || die "No .deb packages found."

echo "Validating ${#DEBS[@]} packages..."

declare -A SEEN=()

for package in "${DEBS[@]}"; do
    "$ROOT/scripts/validate-package.sh" "$package"

    ID="$(dpkg-deb -f "$package" Package):$(dpkg-deb -f "$package" Version):$(dpkg-deb -f "$package" Architecture)"

    [[ -z "${SEEN[$ID]:-}" ]] || die "Duplicate package identity: $ID"

    SEEN["$ID"]=1
done

# The build is intentionally isolated: no previous repository or
# snapshot can interfere with this complete reconstruction.
TEMP_CONFIG="$(mktemp)"
trap 'rm -f "$TEMP_CONFIG"' EXIT

python3 - "$CONFIG" "$TEMP_CONFIG" "$APTLY_ROOT" "$PUBLIC_DIR" <<'PY'
import json
import sys

source, target, root, public = sys.argv[1:]

with open(source, encoding="utf-8") as f:
    config = json.load(f)

config["rootDir"] = root
config["FileSystemPublishEndpoints"] = {
    "public": {
        "rootDir": public,
        "linkMethod": "copy"
    }
}

with open(target, "w", encoding="utf-8") as f:
    json.dump(config, f, indent=2)
PY

APTLY=(aptly -config="$TEMP_CONFIG")

echo "Creating isolated repository..."

"${APTLY[@]}" repo create \
    -distribution="$CODENAME" \
    -component="$COMPONENT" \
    "$REPO_NAME"

"${APTLY[@]}" repo add "$REPO_NAME" "${DEBS[@]}"

"${APTLY[@]}" snapshot create "$SNAPSHOT" from repo "$REPO_NAME"

echo "Publishing signed snapshot..."

"${APTLY[@]}" publish snapshot \
    -batch \
    -gpg-key="$APT_GPG_KEY_ID" \
    -distribution="$CODENAME" \
    -component="$COMPONENT" \
    -architectures="$ARCHITECTURE,all" \
    -acquire-by-hash \
    "$SNAPSHOT" \
    filesystem:public

echo "APT repository generated: $PUBLIC_DIR"
