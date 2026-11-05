<div align="center">

# Anima OSS — APT Repository

**Official package distribution infrastructure for AnimaOS.**

[![Debian](https://img.shields.io/badge/Base-Debian%2013%20Trixie-d70a53?style=flat-square)](https://www.debian.org/)
[![APT](https://img.shields.io/badge/Package%20Manager-APT-35e6ce?style=flat-square)](#)
[![Architecture](https://img.shields.io/badge/Architecture-amd64-35e6ce?style=flat-square)](#)
[![Status](https://img.shields.io/badge/Status-In%20Development-orange?style=flat-square)](#)

</div>

## Overview

Official APT repository infrastructure for AnimaOS.

Manages Debian packages, repository metadata, GPG signing and automated
publication through GitHub Actions.

## Repository

| Property | Value |
|---|---|
| Distribution | Debian 13 Trixie |
| Component | main |
| Architectures | amd64, all |
| Package format | Debian `.deb` |
| Signing | GPG |
| Repository manager | Aptly |
| Publication | GitHub Pages |

## Client configuration

The repository endpoint is planned:

`https://anima-oss.github.io/apt/`

It is not operational until the first successful signed deployment.

See [client setup](docs/client-setup.md).

## Package workflow

1. Build a Debian package.
2. Validate its metadata and architecture.
3. Attach the `.deb` to a GitHub Release.
4. Publish the release.
5. GitHub Actions rebuilds and signs the APT repository.

## Local tests

```bash
./tests/run.sh
```

## Security

- GPG-signed repository metadata.
- Public key distributed separately from the private key.
- Private signing keys stored only in GitHub Actions secrets.
- Packages validated before publication.
- No private keys or package binaries committed to Git.

## Development

This infrastructure is under active development.
