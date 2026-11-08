# Package Maintenance

This repository builds its published APT index from the package catalog at [`config/packages.yml`](../config/packages.yml). The catalog is the source of truth for which Debian packages are included and where their upstream `.deb` assets are obtained.

## Package catalog

Each enabled package entry defines:

- `package`: Debian package name declared inside the `.deb` control metadata.
- `repository`: public GitHub repository containing the upstream Release.
- `tag`: exact GitHub Release tag.
- `asset`: exact `.deb` asset filename attached to that Release.
- `version`: expected Debian package version.
- `architecture`: expected package architecture (`amd64` or `all`).
- `enabled`: whether the package is included in the next publication.

Example:

```yaml
- package: anima-booter
  repository: marrionesa/animabooter
  tag: v0.1.0
  asset: animabooter-linux_AnimaBooter_0.1.0_amd64.deb
  version: "0.1.0"
  architecture: amd64
  enabled: true
```

The `package`, `version` and `architecture` values must match the Debian metadata embedded in the downloaded `.deb`. The asset filename and Release tag must match the upstream GitHub Release exactly.

## Add or update a package

1. Publish the `.deb` asset in an upstream GitHub Release, or identify an existing Release asset.
2. Add a new catalog entry or update the existing entry in `config/packages.yml`.
3. Keep existing package entries enabled unless the package is intentionally being removed from the APT repository. Publication rebuilds the repository from the enabled catalog; it is not an incremental append of a single new file.
4. Run the local tests:

   ```bash
   ./tests/run.sh
   ```

5. Commit and push the catalog change to `main`.
6. Run **Publish AnimaOS APT Repository** manually from GitHub Actions.
7. Verify that the workflow succeeds, GitHub Pages deploys, and the package appears in the published `Packages` index.

A Release published in another GitHub repository does not automatically trigger this repository's workflow. The workflow supports manual dispatch and Releases published in `anima-oss/apt` itself.

## Download and validation

The workflow installs PyYAML and executes:

```bash
python3 scripts/download-packages.py "$GITHUB_WORKSPACE/packages"
```

The downloader reads the catalog and, for each enabled entry:

- Resolves the specified GitHub Release by repository and tag.
- Requires exactly one uploaded asset with the configured filename.
- Downloads the asset into a package-specific staging directory.
- Checks the downloaded size against the GitHub Release asset metadata.
- Checks the SHA-256 digest when the GitHub API provides it.
- Uses `dpkg-deb` to verify `Package`, `Version` and `Architecture` against the catalog.

The publication script then validates each `.deb`, creates an isolated Aptly repository and snapshot, signs the repository metadata and exports the published repository files.

## Local package validation and staging

Validate a Debian package manually:

```bash
./scripts/validate-package.sh path/to/package.deb
```

Stage a package locally, when needed for local maintenance or testing:

```bash
./scripts/import-package.sh path/to/package.deb
```

The `packages/` directory is excluded from Git. The automated publication workflow obtains its package files from the catalog; adding a file to the local staging directory alone does not add it to the published repository.

## Local tests

```bash
./tests/run.sh
```

The test suite checks shell and Python syntax, catalog structure and uniqueness, Aptly configuration, and Debian package validation.

## Signing and publication

GitHub Actions requires these repository secrets:

- `APT_GPG_PRIVATE_KEY`: private key material used to sign repository metadata.
- `APT_GPG_KEY_ID`: signing key ID or fingerprint.

Never commit private GPG material or upload it to GitHub Releases. The public key is exported into the published Pages artifact as `anima-archive-keyring.gpg`.

The publication workflow is started by either:

- Manual dispatch from **Actions → Publish AnimaOS APT Repository → Run workflow**.
- Publishing a Release in `anima-oss/apt`.

Never edit generated repository metadata by hand. Update the catalog or upstream package source, then run the publication workflow.
