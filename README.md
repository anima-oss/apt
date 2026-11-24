 <p align="center">
  <img src="docs/branding/anima-banner.png" alt="ANIMA — asistente personal local" width="100%">
</p>

<div align="center">

# Anima OSS — APT Repository

**Official package distribution infrastructure for AnimaOS.**

[![Debian](https://img.shields.io/badge/Base-Debian%2013%20Trixie-d70a53?style=flat-square)](https://www.debian.org/)
[![APT](https://img.shields.io/badge/Package%20Manager-APT-35e6ce?style=flat-square)](#)
[![Architecture](https://img.shields.io/badge/Architecture-amd64-35e6ce?style=flat-square)](#)
[![Status](https://img.shields.io/badge/Status-Operational-success?style=flat-square)](#)

</div>

## Overview

Official APT repository infrastructure for AnimaOS. It distributes Debian packages through signed repository metadata, with package acquisition and publication automated through GitHub Actions, Aptly, GPG and GitHub Pages.

**APT repository:** <https://anima-oss.github.io/apt/>

The repository can distribute packages from Releases hosted in this repository or in other public GitHub repositories. Upstream `.deb` files are downloaded during the publication workflow; they do not need to be copied into this repository's Releases.

## Repository information

| Property | Value |
|---|---|
| Distribution | Debian 13 Trixie |
| Component | `main` |
| Published architectures | `amd64`, `all` |
| Current package architecture | `amd64` |
| Package format | Debian `.deb` |
| Repository manager | Aptly |
| Repository signing | GPG-signed metadata (`InRelease`) |
| CI/CD | GitHub Actions |
| Hosting | GitHub Pages |
| Status | Operational |

## Installation

### 1. Install the repository signing key

```bash
sudo install -d -m 0755 /etc/apt/keyrings

curl -fsSL https://anima-oss.github.io/apt/anima-archive-keyring.gpg \
  -o /etc/apt/keyrings/anima-archive-keyring.gpg

sudo chmod 0644 /etc/apt/keyrings/anima-archive-keyring.gpg
```

### 2. Configure the repository

```bash
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/anima-archive-keyring.gpg] https://anima-oss.github.io/apt trixie main" \
  | sudo tee /etc/apt/sources.list.d/anima-oss.list
```

### 3. Refresh package indexes

```bash
sudo apt update
```

### 4. Install applications

Install individual applications:

```bash
sudo apt install anima-control
sudo apt install anima-booter
sudo apt install anima-system-suite
```

Or install all applications:

```bash
sudo apt install anima-control anima-booter anima-system-suite
```

Once the repository is configured, APT handles package downloads, installation and subsequent upgrades through the standard package manager.

## Available packages

The repository currently publishes **3 packages**:

| Debian package | Application | Version | Architecture | Description |
|---|---|---:|---|---|
| `anima-control` | ANIMA Control Center | `0.1.0` | `amd64` | Management tools for the AnimaOS desktop environment |
| `anima-booter` | AnimaBooter | `0.1.0` | `amd64` | Cross-platform USB imaging utility with verification and destructive-safety features |
| `anima-system-suite` | ANIMA System Suite | `1.0.0` | `amd64` | Linux system performance monitoring, hardware diagnostics, cooling management and OS optimization |

### `anima-control`

ANIMA Control Center for managing the AnimaOS desktop environment.

Its current feature set includes:

- Network management
- Display configuration
- System diagnostics and system information
- Storage management and disk health
- Battery information
- Software and model management
- Bookmarks and calendar
- Partition management
- Terminal access

Install:

```bash
sudo apt install anima-control
```

### `anima-booter` — AnimaBooter

AnimaBooter is a cross-platform USB imaging utility. The APT repository distributes the official Debian package attached to the upstream `marrionesa/animabooter` GitHub Release. The upstream package is consumed as published; this repository does not rebuild or modify it.

Upstream project and release:

- [AnimaBooter source repository](https://github.com/marrionesa/animabooter)
- [AnimaBooter v0.1.0 release](https://github.com/marrionesa/animabooter/releases/tag/v0.1.0)

Install:

```bash
sudo apt install anima-booter
```

### `anima-system-suite` — ANIMA System Suite

ANIMA System Suite is a native Linux desktop application built with **Tauri v2, Rust, React and TypeScript**. It provides comprehensive system performance monitoring, hardware diagnostics, driver auditing, BIOS and firmware inspection, cooling management and operating system optimization.

Its feature set includes:

- Real-time system health dashboard.
- CPU and RAM monitoring.
- GPU and kernel driver diagnostics.
- BIOS and firmware auditing.
- Secure Boot and boot-time information.
- Hardware temperature monitoring through Linux hwmon interfaces.
- AIO pump and fan monitoring.
- PWM fan control and automatic fan curves.
- Chassis airflow monitoring and balancing.
- OS configuration auditing and optimization.
- One-Click Fix operations with Polkit authorization.
- System temperature alerts and background monitoring.

**Technical information:**

| Property | Value |
|---|---|
| Package | `anima-system-suite` |
| Version | `1.0.0` |
| Architecture | `amd64` |
| Package format | Debian `.deb` |
| Framework | Tauri v2 |
| Backend | Rust |
| Frontend | React + TypeScript |
| Distribution | ANIMA OSS APT |

The application uses real Linux system interfaces and hardware sensors, including `/sys/class/hwmon`, `/sys/class/dmi`, `/proc` and `/sys/firmware/efi`.

When hardware information is unavailable, the application reports unavailable values or explicitly identified estimates rather than inventing sensor readings.

Official project and distribution release:

- [ANIMA System Suite source repository](https://github.com/marrionesa/anima-system-suite)
- [ANIMA System Suite v1.0.0 — Public APT Release](https://github.com/anima-oss/apt/releases/tag/v0.1.0)

Install:

```bash
sudo apt install anima-system-suite
```

## How package publication works

The package catalog in [`config/packages.yml`](config/packages.yml) is the source of truth for the packages included in each publication. Each enabled entry identifies:

- Debian package name, expected version and architecture.
- Upstream GitHub repository and Release tag.
- Exact `.deb` asset filename to download.
- Whether the package is enabled for publication.

For every run, the workflow:

1. Checks out this repository and installs the build dependencies, including Aptly and PyYAML.
2. Runs the infrastructure tests.
3. Imports the private GPG signing key from GitHub Actions secrets.
4. Runs `scripts/download-packages.py` to read `config/packages.yml` and download each enabled asset from its specified GitHub Release.
5. Validates the downloaded asset's availability, size and Debian package metadata. It also checks the GitHub SHA-256 digest when the Release API provides one.
6. Runs `scripts/publish.sh` to build a fresh APT repository from the downloaded `.deb` packages.
7. Exports the public key, signs the repository metadata and verifies the generated `InRelease` file.
8. Publishes the generated repository through GitHub Pages.

The workflow is triggered by either:

- **Manual dispatch** (`workflow_dispatch`) from GitHub Actions.
- **A published Release in `anima-oss/apt`** (`release: published`).

A Release published in an upstream repository does not, by itself, trigger this repository's workflow. After updating an upstream package entry in `config/packages.yml`, run **Publish AnimaOS APT Repository** manually from the Actions tab.

### Adding or updating a package

1. Publish the upstream `.deb` in a GitHub Release (or select an existing Release asset).
2. Add or update its entry in `config/packages.yml`, including the exact Release tag and asset filename. Keep all existing packages that should remain in the repository enabled.
3. Run the local validation tests:

   ```bash
   ./tests/run.sh
   ```

4. Submit the catalog or workflow changes through a Pull Request and merge them into `main`.
5. In GitHub, open **Actions → Publish AnimaOS APT Repository → Run workflow**.
6. Confirm that the run succeeds and that GitHub Pages deploys the generated repository.
7. Verify publication from a client:

   ```bash
   sudo apt update
   apt-cache policy anima-control
   apt-cache policy anima-booter
   apt-cache policy anima-system-suite
   ```

A new Release in `anima-oss/apt` is not required when adding a package whose `.deb` is hosted in an existing Release. The catalog and publication workflow control package inclusion.

## Local tests

Run the repository validation suite from the project root:

```bash
./tests/run.sh
```

The tests check shell and Python syntax, the package catalog, Aptly configuration, Debian package validation and rejection of invalid input.

## Security

- APT repository metadata is GPG-signed and published as `InRelease`.
- The public signing key is distributed separately from the private key.
- The private signing key and key ID are stored in GitHub Actions secrets (`APT_GPG_PRIVATE_KEY` and `APT_GPG_KEY_ID`).
- Downloaded package assets are checked before they enter the repository publication process.
- Upstream `.deb` files are referenced by exact repository, tag and asset name in the package catalog.
- Generated package files, local Aptly state and private signing material must not be committed to Git.

## Project links

- **APT Repository:** <https://anima-oss.github.io/apt/>
- **GitHub Repository:** <https://github.com/anima-oss/apt>
- **GitHub Releases:** <https://github.com/anima-oss/apt/releases>
- **ANIMA Control:** <https://github.com/anima-oss>
- **AnimaBooter:** <https://github.com/marrionesa/animabooter>
- **ANIMA System Suite:** <https://github.com/marrionesa/anima-system-suite>
- **Client Setup:** [docs/client-setup.md](docs/client-setup.md)
- **Package Maintenance:** [docs/package-maintenance.md](docs/package-maintenance.md)

## Development

Anima OSS APT is maintained as part of the AnimaOS software distribution infrastructure. Package inclusion and upstream versions are managed through `config/packages.yml`; repository generation and publication are handled by the automated workflow.