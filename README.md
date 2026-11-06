 <div align="center">

# Anima OSS — APT Repository

**Official package distribution infrastructure for AnimaOS.**

[![Debian](https://img.shields.io/badge/Base-Debian%2013%20Trixie-d70a53?style=flat-square)](https://www.debian.org/)
[![APT](https://img.shields.io/badge/Package%20Manager-APT-35e6ce?style=flat-square)](#)
[![Architecture](https://img.shields.io/badge/Architecture-amd64-35e6ce?style=flat-square)](#)
[![Status](https://img.shields.io/badge/Status-Operational-success?style=flat-square)](#)

</div>

## Overview

Official APT repository infrastructure for AnimaOS.

Provides Debian package distribution, repository metadata management, GPG signing and automated publication through GitHub Actions and GitHub Pages.

Repository URL:

**https://anima-oss.github.io/apt/**

## Repository information

| Property | Value |
|---|---|
| Distribution | Debian 13 Trixie |
| Component | main |
| Architectures | amd64, all |
| Package format | Debian `.deb` |
| Signing | GPG |
| Repository manager | Aptly |
| CI/CD | GitHub Actions |
| Hosting | GitHub Pages |
| Status | Operational |

## Installation

### 1. Add the repository signing key

```bash
sudo install -d -m 0755 /etc/apt/keyrings

curl -fsSL https://anima-oss.github.io/apt/anima-archive-keyring.gpg \
  | sudo tee /etc/apt/keyrings/anima-archive-keyring.gpg >/dev/null

sudo chmod 0644 /etc/apt/keyrings/anima-archive-keyring.gpg
```

### 2. Add the APT repository

```bash
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/anima-archive-keyring.gpg] https://anima-oss.github.io/apt trixie main" \
  | sudo tee /etc/apt/sources.list.d/anima-oss.list
```

### 3. Update package indexes

```bash
sudo apt update
```

### 4. Install applications

```bash
sudo apt install anima-control
```

Once configured, applications can be installed and updated through the standard APT package manager.

## Available packages

The repository currently contains **1 published package**.

| Package | Version | Architecture | Description |
|---|---|---|---|
| `anima-control` | 0.1.0 | amd64 | ANIMA Control Center |

### anima-control

ANIMA Control Center for managing the AnimaOS desktop environment.

Features include:

- Network management
- Display configuration
- System diagnostics
- System information and summary
- Storage management
- Disk health
- Battery information
- Software management
- Model management
- Bookmarks
- Calendar
- Partition management
- Terminal access

Install:

```bash
sudo apt install anima-control
```

## Package workflow

1. Build a Debian package.
2. Validate package metadata and architecture.
3. Attach the `.deb` package to a GitHub Release.
4. Publish the release.
5. GitHub Actions downloads and validates packages.
6. Aptly generates repository metadata.
7. GPG signs the repository metadata.
8. GitHub Pages publishes the updated repository.

## Local tests

Run the repository validation tests:

```bash
./tests/run.sh
```

## Security

- GPG-signed repository metadata.
- Public signing key distributed separately from the private key.
- Private signing keys stored exclusively in GitHub Actions secrets.
- Packages validated before publication.
- No private signing keys committed to Git.

## Links

- **APT Repository:** https://anima-oss.github.io/apt/
- **GitHub Repository:** https://github.com/anima-oss/apt
- **GitHub Releases:** https://github.com/anima-oss/apt/releases
- **Client Setup:** [docs/client-setup.md](docs/client-setup.md)
- **Package Maintenance:** [docs/package-maintenance.md](docs/package-maintenance.md)

## Development

Anima OSS APT is actively maintained as part of the AnimaOS software distribution infrastructure.
