# Package Maintenance

Validate a Debian package:

```bash
./scripts/validate-package.sh package.deb
```

Stage a package locally:

```bash
./scripts/import-package.sh package.deb
```

Packages are excluded from Git.

Create a GitHub Release and attach Debian packages as `.deb` assets.
The publication workflow rebuilds the repository from release assets.

Never upload private GPG material to GitHub Releases.
