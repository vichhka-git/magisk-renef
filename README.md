# MagiskRenef

A [Magisk](https://github.com/topjohnwu/Magisk) / [KernelSU](https://github.com/tiann/KernelSU) / [APatch](https://github.com/bmax121/APatch) module that automatically packages and runs [renef](https://github.com/Ahmeth4n/renef) — a dynamic instrumentation toolkit for Android.

Inspired by [magisk-frida](https://github.com/ViRb3/magisk-frida).

## Requirements

- Rooted Android device (Magisk / KernelSU / KernelSU Next / APatch)
- **ARM64 only** — renef only supports ARM64 Android
- Android 10+ recommended

## Installation

1. Download the latest `MagiskRenef-{version}.zip` from [Releases](https://github.com/vichhka-git/magisk-renef/releases)
2. Install via your root manager (Magisk / KSU / APatch)
3. Reboot

After reboot, `renef_server` starts automatically using **UDS** (Unix Domain Socket) on abstract socket `@com.android.internal.os.RuntimeInit`.

## Usage

Connect from your host machine using the renef client:

```bash
# Spawn a new process
renef -s com.example.app -l your-script.lua

# Attach to running process (open the app first)
adb shell su 0 sh -c "pidof com.example.app"   # get PID
renef -a <PID> -l your-script.lua
```

## Module Status

After reboot, check your root manager's module list:
- ✅ `renef_server is running (UDS)` — healthy
- ❌ `renef_server failed to start` — see Troubleshooting

## Troubleshooting

### renef_server failed to start

Check the server log:
```bash
adb shell su 0 cat /data/local/tmp/renef_server.log
```

### Injection Fails — `Failed to find libc base`

Possible causes:

- **SELinux enforcing** — most common cause on custom ROMs / Samsung devices:
  ```bash
  adb shell su -c setenforce 0
  ```
  Then retry. If it works, the issue is SELinux blocking renef's process injection.

- **Device not rooted** — renef_server must run as root (uid 0)

- **Wrong architecture** — only ARM64 is supported

### Spawning Fails — banking/hardened apps

Some apps set `android:exported="false"` on all activities. The `-s` (spawn) flag uses `monkey` which cannot launch them. Use `-a` (attach) instead:

```bash
# 1. Open the app manually on your device
# 2. Get its PID
adb shell su 0 sh -c "pidof com.example.app"
# 3. Attach
renef -a <PID> -l your-script.lua
```

## How It Works

A GitHub Actions workflow runs daily. When a new renef release is detected, it:

1. Downloads `renef-v{VERSION}-android-arm64.tar.gz` from the renef releases
2. Extracts `renef_server` and `libagent.so`
3. Packages them into a Magisk-compatible ZIP
4. Publishes a new GitHub release

## Building Locally

```bash
# Install uv (https://docs.astral.sh/uv/)
uv run python3 main.py

# Force a rebuild
FORCE_RELEASE=1 uv run python3 main.py
```

## Credits

- [renef](https://github.com/Ahmeth4n/renef) by Ahmeth4n
- [magisk-frida](https://github.com/ViRb3/magisk-frida) by ViRb3 (structure inspiration)
