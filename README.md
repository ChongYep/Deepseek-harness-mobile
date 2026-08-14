# DeepSeek Harness Mobile

The [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness) agent, running **on your Android phone** — a SillyTavern-style mobile chat UI over a real on-device agent that reads files, runs commands, and edits code. No cloud round-trip: the agent, your files, and your model key all stay on the device.

English | [中文](README.zh.md)

> **Heads-up — this is not a native app.** You launch it as a **web page** in the phone's browser; the agent itself runs under [Termux](https://termux.dev/) on the device. There is no standalone APK — Termux must stay running for the agent to be reachable.

## What it is

DeepSeek Harness is an on-device AI coding agent. This project is its **Android distribution**: the agent core runs under [Termux](https://termux.dev/) on the phone, and you talk to it from the phone's browser at `http://127.0.0.1:3080`.

On a phone viewport (≤ 767 px) the web UI renders a single-column mobile shell — the sidebar and the session-details panel slide in as drawers — instead of the desktop three-column grid. The conversation fills the screen; the composer sits pinned at the bottom.

## Screenshots

| Mobile chat | Sidebar drawer | Details drawer |
| --- | --- | --- |
| ![mobile chat](01-base.png) | ![sidebar](02-sidebar.png) | ![details](03-details.png) |

## Why on-device

- **Privacy** — your files and model API key never leave the phone.
- **No cloud server** — the agent is local, so there is no subscription or always-on server to trust.
- **Loopback-only** — the web RPC is unauthenticated by design, but it binds `127.0.0.1`, which the phone browser shares on the device loopback; nothing listens on the LAN.

## Requirements

- An **arm64-v8a** Android phone with **8 GB+ RAM** (a flagship SoC runs everything comfortably — the core is pure JavaScript plus the builtin `node:sqlite`).
- [Termux](https://termux.dev/) installed from **F-Droid** (the Play Store build is stale).

## Install

1. Install the base packages and the CLI:

   ```sh
   pkg update -y && pkg upgrade -y
   pkg install -y nodejs-lts git bash
   npm install --global @deepseek-ai/dsh
   ```

   `node-pty` (an optional native addon) may print a native-build warning on Termux — that is **expected and harmless**; the install continues.

2. Copy this repository's `install/` folder onto the phone, then run the patcher:

   ```sh
   cd install
   bash install.sh
   ```

   The patcher installs the mobile shell and the Android runtime patches (optional native addons, filesystem fallbacks, directory-picker timeout + retry) as local `0.1.0-rc.7` packages over the published CLI.

## Run

```sh
export DSH_HOME="$HOME/.dsh"
export DSH_PERMISSION_MODE=danger-full-access
export DSH_TELEMETRY_DISABLED=1
node --expose-internals \
  /data/data/com.termux/files/usr/lib/node_modules/@deepseek-ai/dsh/lib/bin.js \
  web --port 3080
```

Open `http://127.0.0.1:3080` in the phone browser, enter your model API key on the Models page, create a session, and send a command — for example, *"run a bash command that prints the device model"*.

## Security

- **Loopback only.** The web RPC is a remote code execution surface by design and is **unauthenticated**. It binds `127.0.0.1`, shared with the phone browser on the device loopback, so nothing listens on the LAN. Do not add `--host 0.0.0.0`.
- **`DSH_PERMISSION_MODE=danger-full-access`.** Android has no `bwrap`/Landlock/Seatbelt/ACL sandbox backend, so the sandbox seam fails closed. The launcher opts into running unconfined — treat the agent like shell access.
- **`DSH_TELEMETRY_DISABLED=1`** keeps session telemetry off by default.

## What this project patches vs. upstream

This distribution carries a small, self-contained set of patches over `deepseek-ai/deepseek-harness` so it installs and runs on Android:

- **Mobile single-column shell** (`client/ui-layout`) — a viewport-conditional branch that reuses the existing layout store, no mobile-specific state.
- **Optional native addons** — `koffi` and `sharp` move to `optionalDependencies` and lazy-load, and `node-pty` reports a clean `TerminalUnavailableError` on Android, so `npm install -g` succeeds where no prebuilt binary exists.
- **Android filesystem fallbacks** — `link(2)` hard links are rejected on Android's FUSE/SELinux, so session logs, the write tool, and attachment storage fall back to `rename()` / `copyFile(COPYFILE_EXCL)`.
- **Directory picker timeout + retry** — a bounded directory-listing scan fails with a retryable error and a one-tap retry button, so a stalled storage pass never hangs the request.
- **Plugin-bundle caching** — client plugin bundles are served `immutable` (the URL carries a content-hash rev) so reloads skip re-fetching the whole plugin graph.
- **HMR needs `--expose-internals`** — the launcher passes it so the HMR service mounts on Android.
- **`$PREFIX/bin/bash`** — the terminal shell path is substituted on Android.

## Keeping the agent alive

- `termux-wake-lock` (from `termux-api`) keeps the CPU awake.
- Run inside `tmux` so the agent survives an accidental Terminal swipe-away: `tmux` → `dsh-web` → `Ctrl-b d` to detach, `tmux attach` to return.

## Credits

A fork of [deepseek-ai/deepseek-harness](https://github.com/deepseek-ai/deepseek-harness). Licensed under the same terms as upstream.
