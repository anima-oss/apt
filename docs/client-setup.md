# AnimaOS APT Client Setup

Target distribution: Debian 13 Trixie, amd64.

Do not configure this repository until its first signed publication
is available and the public key fingerprint has been independently verified.

Install the public key:

```bash
sudo install -d -m 0755 /etc/apt/keyrings

curl -fsSL \
  https://anima-oss.github.io/apt/anima-archive-keyring.gpg \
  -o /etc/apt/keyrings/anima-archive-keyring.gpg

sudo chmod 0644 /etc/apt/keyrings/anima-archive-keyring.gpg
```

Configure APT:

```bash
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/anima-archive-keyring.gpg] https://anima-oss.github.io/apt trixie main" \
  | sudo tee /etc/apt/sources.list.d/anima-oss.list

sudo apt update
```

Verify the key fingerprint through an independently published
Anima OSS security channel before trusting it.
