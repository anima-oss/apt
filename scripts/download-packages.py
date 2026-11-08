#!/usr/bin/env python3
import fnmatch
import hashlib
import json
import re
import shutil
import subprocess
import sys
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

import yaml


ROOT = Path(__file__).resolve().parent.parent
CATALOG = ROOT / "config" / "packages.yml"
DESTINATION = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else ROOT / "packages"
USER_AGENT = "AnimaOS-APT-Package-Importer"


def fail(message):
    raise SystemExit(f"ERROR: {message}")


def request(url, accept="application/vnd.github+json"):
    req = urllib.request.Request(
        url,
        headers={
            "User-Agent": USER_AGENT,
            "Accept": accept,
            "X-GitHub-Api-Version": "2022-11-28",
        },
    )
    return urllib.request.urlopen(req, timeout=60)


def read_catalog():
    try:
        data = yaml.safe_load(CATALOG.read_text(encoding="utf-8"))
    except Exception as exc:
        fail(f"Cannot read package catalog: {exc}")

    if not isinstance(data, dict) or data.get("schema_version") != 1:
        fail("Unsupported or invalid package catalog schema.")

    packages = data.get("packages")
    if not isinstance(packages, list) or not packages:
        fail("The catalog contains no packages.")

    seen = set()
    required = {
        "package", "repository", "tag", "asset",
        "version", "architecture", "enabled",
    }

    for item in packages:
        if not isinstance(item, dict) or not required.issubset(item):
            fail(f"Invalid package entry: {item!r}")

        name = item["package"]
        if not isinstance(name, str) or not re.fullmatch(
            r"[a-z0-9][a-z0-9+.-]+", name
        ):
            fail(f"Invalid Debian package name: {name!r}")

        if name in seen:
            fail(f"Duplicate catalog package: {name}")
        seen.add(name)

        if not re.fullmatch(
            r"[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+",
            item["repository"],
        ):
            fail(f"Invalid GitHub repository: {item['repository']!r}")

        if not isinstance(item["tag"], str) or not item["tag"]:
            fail(f"Invalid release tag for {name}")

        asset = item["asset"]
        if not isinstance(asset, str) or Path(asset).name != asset:
            fail(f"Invalid release asset name for {name}")

        if not asset.endswith(".deb"):
            fail(f"Release asset is not a Debian package: {asset}")

        if item["architecture"] not in ("amd64", "all"):
            fail(f"Unsupported architecture for {name}")

        if not isinstance(item["enabled"], bool):
            fail(f"'enabled' must be boolean for {name}")

    return packages


def get_release(repository, tag):
    encoded_tag = urllib.parse.quote(tag, safe="")
    url = (
        f"https://api.github.com/repos/{repository}"
        f"/releases/tags/{encoded_tag}"
    )

    try:
        with request(url) as response:
            release = json.load(response)
    except Exception as exc:
        fail(f"Cannot retrieve {repository} release {tag}: {exc}")

    if release.get("draft"):
        fail(f"Release {repository}@{tag} is a draft.")

    return release


def download_package(item):
    name = item["package"]
    repository = item["repository"]
    tag = item["tag"]
    asset_name = item["asset"]

    print(f"\n=== {name} {item['version']} ===")
    print(f"Source: {repository}@{tag}")
    print(f"Asset:  {asset_name}")

    release = get_release(repository, tag)
    matches = [
        asset for asset in release.get("assets", [])
        if asset.get("name") == asset_name
        and asset.get("state") == "uploaded"
    ]

    if len(matches) != 1:
        fail(
            f"Expected exactly one uploaded asset '{asset_name}' "
            f"in {repository}@{tag}; found {len(matches)}."
        )

    asset = matches[0]
    target_dir = DESTINATION / name
    target_dir.mkdir(parents=True, exist_ok=True)

    # Elimina únicamente los .deb anteriores de este paquete.
    for old in target_dir.glob("*.deb"):
        old.unlink()

    target = target_dir / asset_name
    temporary = target.with_suffix(target.suffix + ".part")

    try:
        with request(
            asset["browser_download_url"],
            accept="application/octet-stream",
        ) as response, temporary.open("wb") as output:
            shutil.copyfileobj(response, output)

        actual_size = temporary.stat().st_size
        if actual_size <= 0 or actual_size != asset["size"]:
            fail(
                f"Asset size mismatch for {name}: "
                f"expected {asset['size']}, got {actual_size}."
            )

        expected_digest = asset.get("digest")
        if expected_digest and expected_digest.startswith("sha256:"):
            digest = hashlib.sha256(temporary.read_bytes()).hexdigest()
            if digest.lower() != expected_digest.split(":", 1)[1].lower():
                fail(f"SHA-256 mismatch for {name}.")

        package_name = subprocess.check_output(
            ["dpkg-deb", "-f", str(temporary), "Package"],
            text=True,
        ).strip()

        version = subprocess.check_output(
            ["dpkg-deb", "-f", str(temporary), "Version"],
            text=True,
        ).strip()

        architecture = subprocess.check_output(
            ["dpkg-deb", "-f", str(temporary), "Architecture"],
            text=True,
        ).strip()

        expected = (
            item["package"],
            item["version"],
            item["architecture"],
        )
        actual = (package_name, version, architecture)

        if actual != expected:
            fail(
                f"Package metadata mismatch for {name}: "
                f"expected {expected}, got {actual}."
            )

        temporary.replace(target)

    except Exception:
        temporary.unlink(missing_ok=True)
        raise

    print(f"DOWNLOADED: {target}")
    print(f"SIZE: {actual_size} bytes")
    print(f"VALIDATED: {package_name} {version} {architecture}")


def main():
    if len(sys.argv) > 2:
        fail("Usage: download-packages.py [destination-directory]")

    if shutil.which("dpkg-deb") is None:
        fail("dpkg-deb is required.")

    DESTINATION.mkdir(parents=True, exist_ok=True)

    packages = read_catalog()
    enabled = [item for item in packages if item["enabled"]]

    if not enabled:
        fail("No enabled packages in catalog.")

    print(f"Loading {len(enabled)} enabled package(s)...")

    for item in enabled:
        download_package(item)

    print(f"\nSuccessfully downloaded {len(enabled)} package(s).")


if __name__ == "__main__":
    main()
