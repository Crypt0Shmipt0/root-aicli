# FAQ

## What does Root.AICLI actually do?

It is a 25 KB Android app that asks your root manager for su access,
then runs four open-source shell modules that install the official AI
coding CLIs from Anthropic, Google, OpenAI, and xAI inside your Termux.
Each module handles the Android/Termux quirks (Bionic vs glibc/musl,
SELinux MLS contexts, mount namespaces) that prevent the vendors'
plain `curl | bash` installers from working out of the box.

Plus a one-time **Permanent Fix** action that prevents the recurring
"Termux broke after pkg upgrade" problem most rooted-Termux users hit.

## Why does this app need root?

To write into Termux's private app-data directory at
`/data/data/com.termux/files/` from outside the Termux app itself.
Android isolates per-app private storage by both POSIX UID and SELinux
MLS categories; without root and the right mount namespace, no app
can see another app's files.

Root is required for:

1. Reading and writing the AI CLI binaries that land in Termux home.
2. Running `chcon` to relabel files with Termux's MLS categories so
   the Termux app can read them.
3. Installing the boot-time persistence hook in
   `/data/adb/service.d/` (Magisk) or `/data/adb/post-fs-data.d/`
   (KernelSU/APatch).

## Does it phone home? Telemetry?

No. The app makes zero network calls of its own. The only network
traffic during an install is the vendor's official installer (which
you trigger by tapping a button) and Termux's own `pkg upgrade` if
you tap **PERMANENT FIX**. We do not collect crash reports, install
counts, or anything else.

## Do you store my API keys?

We never see them. Auth is handled entirely by each CLI's own
first-run flow inside Termux. Root.AICLI does not touch
`ANTHROPIC_API_KEY`, `OPENAI_API_KEY`, `XAI_API_KEY`, or any OAuth
tokens.

## Is the APK safe? Why is it not on Play Store?

Play Store does not list apps that require root by default. F-Droid
does (a submission is in progress; see CHANGELOG).

The APK is open source. The signing keystore is committed to the repo
(intentional, so anyone can produce a byte-identical APK). The signature
is for tamper-detection during install, not for trust pinning.

If you want a higher trust bar, build from source. See
[INSTALLATION.md](./INSTALLATION.md#path-c---build-from-source).

## Which Android versions are supported?

Android 8.0 (API 26) and up. The app is built against SDK 34 (Android 14)
but the runtime requirements are conservative: just `Activity`,
`Runtime.exec`, and `Magisk-style su -mm`.

## Which root managers are supported?

- **Magisk** - full support, including boot persistence
- **KernelSU** - full support, boot persistence via `post-fs-data.d`
- **APatch** - full support, same as KernelSU

If your root manager exposes a `su` binary that supports `--mount-master`
(the `-mm` flag) and writes to `/data/adb/service.d/` or
`/data/adb/post-fs-data.d/`, it should work. File an issue if it does
not and we will add detection logic.

## Why does my Termux break every few weeks?

This is the most common rooted-Termux problem and the reason
**PERMANENT FIX** exists. Two root causes:

1. Termux's apt sometimes writes `.so` files with mode 600 (no execute).
   The dynamic linker cannot mmap them with PROT_EXEC, so bash and
   anything that depends on the affected library refuses to start.

2. Files written under `su` (Anthropic auto-update, this very app, an
   unattended `pkg upgrade`) land with the no-categories SELinux
   context `u:object_r:app_data_file:s0`. Termux's app SELinux domain
   requires matching MLS categories or it sees "exec: Operation not
   permitted" disguised as "no such file or directory."

The Permanent Fix boot hook heals both on every reboot. After enabling
it once, Termux should stop spontaneously breaking.

## "Tap doesn't do anything" - what is wrong?

A few possibilities:

1. Your device has a game-mode overlay (Odin GameAssistant, Samsung
   Game Booster, ASUS Game Genie, ROG Game Center, MediaTek Game
   Center) that swallows touches. Workaround: use TAB navigation -
   plug in a keyboard or use the on-screen keyboard's TAB key to
   move focus button by button, then ENTER to activate. We are
   tracking this in [KNOWN-ISSUES.md](./KNOWN-ISSUES.md).

2. The Magisk grant dialog showed and you dismissed it instead of
   tapping Grant. Tap any button again to re-prompt.

3. Termux is not installed from the right source. The Play Store
   build of Termux has a different signature and won't work with
   companion apps. Reinstall from F-Droid.

## Why are some buttons orange?

Color coding:

- Green: status check, read-only, fast (no install)
- Blue: per-CLI installer
- Orange: long-running or potentially-destructive actions (install
  all, permanent fix)

The orange ones are slower (30+ seconds each) or write to
`/data/adb/`, so we wanted them to look slightly different from the
quick individual installs.

## Can I install just one CLI?

Yes. Each install button is independent. **INSTALL ALL** is purely a
convenience that chains them in sequence.

## What happens if I tap an install button when the CLI is already there?

It re-runs the installer, which acts as an update if the upstream
version moved, or a no-op if you are already current. Idempotent and
safe.

## Can I uninstall a single CLI?

Yes. Open Termux and use the CLI's own uninstall path:

| CLI | Uninstall |
|---|---|
| Claude Code (bare) | `npm uninstall -g @anthropic-ai/claude-code` |
| Claude Code (Alpine) | `proot-distro login alpine -- npm uninstall -g @anthropic-ai/claude-code` |
| Antigravity | `rm -rf ~/.local/bin/agy ~/.local/bin/agy.bin ~/.local/bin/agy.va39` |
| Codex | `rm -rf ~/.codex ~/.local/bin/codex ~/.local/bin/codex-*` |
| Grok (bare) | `rm -rf ~/.grok ~/.local/bin/grok` |
| Grok (Alpine) | `proot-distro login alpine -- rm -rf /root/.grok /usr/local/bin/grok` |

## How do I uninstall Root.AICLI itself?

Android Settings -> Apps -> Root.AICLI -> Uninstall.

The boot persistence hook stays unless you remove it manually:

```sh
su -c "rm -f /data/adb/service.d/root-aicli-persist.sh"
su -c "rm -f /data/adb/post-fs-data.d/root-aicli-persist.sh"
```

The installed CLIs also stay; see the per-CLI uninstall commands
above.

## Does this work on non-handheld devices?

It should work on any rooted Android 8+ device with Termux from
F-Droid. Tested most heavily on the Ayn Odin 3 handheld so far.
Reports welcome - file an issue with your device, Android version,
and the **STATUS** output to add yours to
[COMPATIBILITY.md](./COMPATIBILITY.md).

## Why is the app only 25 KB?

Because it is the minimum thing that can call `su` and show a log.
No Compose, no Gradle, no androidx, no Material library, no Kotlin
stdlib. Just a native `View` hierarchy with eight buttons and a
`TextView`, plus `Runtime.exec`. A Compose-based version would be
about 8 MB.

The actual install logic lives in shell modules on disk, not in the
APK. That means you can update the install logic by editing
`~/root-aicli/modules/*.sh` directly without rebuilding the APK.

## Can I contribute a new CLI?

Yes. See [CONTRIBUTING.md](./CONTRIBUTING.md#adding-a-new-cli).

## Where do I report bugs?

https://github.com/Crypt0Shmipt0/root-aicli/issues with the bug-report
template.
