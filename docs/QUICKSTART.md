# Quickstart - five minutes to a working Claude/Codex/agy/Grok in Termux

If you already have a rooted Android device with Termux installed, this
walks you from zero to a working AI coding CLI session in roughly five
minutes.

## Prerequisites checklist

Before you start, you need all of these:

- [ ] Android 8 or newer
- [ ] A root manager installed: Magisk **or** KernelSU **or** APatch
- [ ] Termux from F-Droid: https://f-droid.org/packages/com.termux/
      (the Play Store version has a different signature and will not
      cooperate with companion apps)
- [ ] About 500 MB of free space (each CLI is 100-200 MB)

Optional but recommended:

- [ ] Termux:Boot (so sshd autostarts after reboot)
- [ ] Termux:Widget (one-tap shortcuts)
- [ ] Termux:API (for `termux-toast` notifications)

## Step 1 - install Root.AICLI

Download `RootAICLI.apk` from the latest release:

  https://github.com/Crypt0Shmipt0/root-aicli/releases/latest

Tap to install. Android will warn you about an unknown source; that is
normal for sideloaded apps. Approve.

Open Root.AICLI from the app drawer.

## Step 2 - grant root

The first action you tap will pop a root prompt from your root manager.

- Magisk: "Superuser Request" dialog. Pick **Forever** in the dropdown,
  then tap **Grant**.
- KernelSU: similar dialog. Set the app to "Allow" with the lifetime
  you prefer.
- APatch: similar. Set "Allow" and "Remember".

## Step 3 - check your environment

Tap **STATUS**. The log pane should show:

```
[+] Termux installed
[+] Root manager: <Magisk|KernelSU|APatch>
[+] su -c id: uid=0 (root works)
[+] Runtime preference: <alpine|bionic>
...
[exit 0]
```

If anything is red, fix that first. The
[Troubleshooting guide](./TROUBLESHOOTING.md) lists the common ones.

## Step 4 - install your first CLI

Tap one of the install buttons. We recommend **INSTALL CODEX** first
because it has the simplest install path (a native musl binary that
runs on bare Termux without Alpine).

The log pane streams the install live. When it finishes you will see
`[exit 0]`. The whole thing takes 30 to 90 seconds depending on your
network.

## Step 5 - apply the boot hook

Tap **PERMANENT FIX** once. This installs a script that runs at every
boot to re-apply Termux SELinux contexts and fix any `.so` file
permission breakage caused by Termux package updates. Without this,
Termux periodically breaks after `pkg upgrade` and you have to ADB in
to fix it.

This takes about 30 to 60 seconds (it sweeps `$PREFIX/lib`).

## Step 6 - open Termux and authenticate

Open Termux. Run the CLI you just installed:

```sh
codex                              # or claude, agy, grok
```

Each CLI handles auth differently. See the
[CLI Reference](./CLI-REFERENCE.md) for per-CLI details.

The fastest headless path for each is:

| CLI | Headless |
|---|---|
| Claude Code | `export ANTHROPIC_API_KEY=...` |
| OpenAI Codex | `export OPENAI_API_KEY=...` |
| xAI Grok | `export XAI_API_KEY=...` |
| Antigravity (agy) | (Google OAuth only, no headless option) |

Put the export line in your `~/.bashrc` so it persists across Termux
sessions.

## What's next

- Read [CLI Reference](./CLI-REFERENCE.md) to learn how to use each CLI.
- Read [FAQ](./FAQ.md) for the most common questions.
- Read [Architecture](./ARCHITECTURE.md) if you want to understand
  the five non-obvious Android/Termux interactions that made this app
  necessary.
- Read [Troubleshooting](./TROUBLESHOOTING.md) when something breaks.
