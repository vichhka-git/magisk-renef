# MagiskRenef

A Magisk module that automatically packages and runs [renef](https://github.com/Ahmeth4n/renef) — a dynamic instrumentation toolkit for Android — as a system service.

Inspired by [magisk-frida](https://github.com/ViRb3/magisk-frida).

## Features

- 🔄 **Auto-updating**: GitHub Actions checks for new renef releases daily and publishes a new module ZIP automatically
- 🚀 **Auto-start**: `renef_server` starts at boot and runs in the background
- 📦 **Supports**: Magisk, KernelSU, APatch
- ⚠️ **ARM64 only** (renef limitation)

## Installation

1. Download the latest `MagiskRenef-*.zip` from [Releases](../../releases)
2. Flash it via **Magisk Manager**, **KernelSU**, or **APatch**
3. Reboot

## Usage

After reboot, `renef_server` runs automatically on port **1907**.

Connect from your host machine:

```bash
# Forward the port
adb forward tcp:1907 tcp:1907

# Use the renef client
renef <command>
```

The module description in your root manager will show:
- ✅ `renef_server is running — port 1907` — healthy
- ❌ `renef_server failed to start` — check logs

## Updating

The module supports Magisk's `updateJson` — your root manager will notify you when a new version is available.

## Building Locally

```bash
# Install uv (https://docs.astral.sh/uv/)
curl -LsSf https://astral.sh/uv/install.sh | sh

# Run the build
uv run python3 main.py

# Output: build/MagiskRenef-*.zip
```

Set `FORCE_RELEASE=1` to force a build even if no new renef version is available:

```bash
FORCE_RELEASE=1 uv run python3 main.py
```

## Project Structure

```
magisk-renef/
├── .github/workflows/main.yml   # Daily CI/CD, auto-release
├── base/
│   ├── customize.sh             # Magisk install hook
│   ├── service.sh               # Boot service (starts renef_server)
│   ├── utils.sh                 # Shared shell utilities
│   └── META-INF/                # Magisk module metadata
├── build/                       # Build output (generated)
├── downloads/                   # Cached renef binaries (generated)
├── main.py                      # Entry point — checks for updates
├── build.py                     # Download, extract, package module ZIP
├── util.py                      # GitHub API helpers
└── pyproject.toml
```

## How It Works

1. `main.py` queries the [renef GitHub releases API](https://github.com/Ahmeth4n/renef/releases) for the latest version
2. Compares against the latest git tag in this repo
3. If new: downloads `renef-v{VERSION}-android-arm64.tar.gz`, extracts `renef_server` + `libagent.so`
4. Packages everything into a Magisk-compatible ZIP with `module.prop`, `customize.sh`, `service.sh`
5. GitHub Actions creates a new release with the ZIP and `updater.json`

## License

MIT
