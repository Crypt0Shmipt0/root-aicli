# Announce drafts

Ready-to-post copy for the venues where rooted-Android + Termux + AI-CLI
users actually hang out. Copy, edit voice if you want, paste.

**House rules:** post these as **yourself**, not as a brand voice. Engage
in comments. Do not crosspost the identical text to multiple
subreddits in the same hour (anti-spam filters). Spread over a week.

---

## r/termux

**Title**: `[Tool] Root.AICLI - one-tap installer for Claude Code, Codex, Antigravity, and Grok in rooted Termux`

**Body**:

I got tired of redoing the same dance every time my Odin's Termux
broke after a `pkg upgrade` or every time Anthropic shipped a new
Claude version that needed reinstalling, so I open-sourced the tool
I wrote for it.

**What it does**

A 25 KB Android app with eight buttons. Tap one, it installs (or
repairs) one of the four major AI coding CLIs inside your Termux:

- Claude Code (Anthropic) - via the official native installer in
  Alpine when present, or pinned to 2.1.112 on bare Termux (last
  version that works on Bionic)
- Antigravity / `agy` (Google) - via wallentx's Termux fork (Bionic
  bridge + TCMalloc 39-bit-VA patch)
- OpenAI Codex CLI - native arm64-musl, works on bare Termux
- xAI Grok Build CLI - official installer with Alpine fallback

Plus a Permanent Fix button that installs a Magisk/KernelSU/APatch
boot hook to re-apply Termux SELinux MLS contexts after every reboot,
which prevents the "Termux randomly stops working after a package
upgrade" problem.

**What it does NOT do**

- No telemetry, no analytics
- Does not bundle vendor binaries (calls the official upstream
  installers)
- Does not touch your API keys

**Source + APK**: https://github.com/Crypt0Shmipt0/root-aicli

MIT. Tested on Magisk + Android 15 + Termux 0.118.3 + Alpine proot.
Reports from other devices welcome.

Feedback / bugs / device reports very welcome.

---

## r/MagiskRoot

**Title**: `Root.AICLI - tiny Android app that installs the official AI coding CLIs in your Termux, with a Magisk boot hook that prevents the recurring Termux breakage`

**Body**:

Open sourced a small app that scratches a Magisk-specific itch.

Most rooted-Termux folks know the pattern: Termux works fine for a
month, you run `pkg upgrade`, and then bash dies with `library
libreadline.so.8 not found` or `exec: Operation not permitted`. Two
overlapping bugs:

1. apt occasionally writes `.so` files with mode 600 (no execute)
2. anything written under su loses Termux's SELinux MLS categories

Root.AICLI's **Permanent Fix** button writes a `/data/adb/service.d/`
script that heals both on every boot. Once-and-done, you stop
chasing the issue.

The same app also one-taps installs of Claude Code, Antigravity,
Codex, and Grok in Termux. The actual install logic is open-source
shell modules, so you can also use it as a reference if you want
to roll your own.

Magisk-only? No - I also wired up KernelSU and APatch boot-hook paths.
Reports from KernelSU/APatch users welcome.

https://github.com/Crypt0Shmipt0/root-aicli

MIT, no telemetry, 25 KB APK, source + signed release on GitHub.

---

## r/LocalLLaMA (or r/ChatGPTCoding)

**Title**: `Sideloaded Claude Code, Codex, agy, and Grok onto a rooted Android handheld with a tiny installer app`

**Body**:

If you have a rooted Android device and you've ever wanted to run
the agentic terminal clients (Claude Code, OpenAI Codex CLI, xAI
Grok Build, Google Antigravity) directly on your phone or
handheld instead of just on a desktop, this is the toolkit I wish
existed two years ago.

Open-source, 25 KB Android APK, MIT licensed. Each install button
calls the **official vendor installer** (no rehosted binaries),
auto-detects whether your Termux can run the binary natively or
needs an Alpine proot, and handles the Android-specific quirks
(SELinux MLS contexts, Magisk mount namespaces, the
`libreadline.so.8` permission issue) that prevent the plain curl-pipe
installers from working out of the box.

Tested on an Ayn Odin 3, but should work on any rooted Android 8+ with
Magisk, KernelSU, or APatch.

https://github.com/Crypt0Shmipt0/root-aicli

The README has a [5-minute quickstart](https://github.com/Crypt0Shmipt0/root-aicli/blob/main/docs/QUICKSTART.md)
and a [per-CLI auth reference](https://github.com/Crypt0Shmipt0/root-aicli/blob/main/docs/CLI-REFERENCE.md)
that covers the headless API-key path for each (because typing
OAuth tokens on a 5-inch handheld is hell).

---

## XDA Apps & Games

**Title**: `[APP][6.0+][Root] Root.AICLI - install Claude Code / Codex / agy / Grok CLIs into Termux with one tap`

**Body**:

Cross-posted from r/termux because I want device reports from XDA
users with diverse hardware:

Root.AICLI is a 25 KB open-source Android app that installs four AI
coding CLIs into a Termux session on rooted devices. Auto-detects
Magisk vs KernelSU vs APatch, picks Alpine vs bare Bionic per CLI,
and installs a boot hook that prevents the recurring
Termux-breaks-after-pkg-upgrade pattern.

**Source**: https://github.com/Crypt0Shmipt0/root-aicli (MIT)
**APK**: https://github.com/Crypt0Shmipt0/root-aicli/releases/latest

Supports Android 8+, all major root managers, both bare Termux and
Alpine proot-distro install paths.

**Looking for device reports** to populate the compatibility matrix.
If you try it, please file a brief issue with the
[device-report template](https://github.com/Crypt0Shmipt0/root-aicli/issues/new?template=device-report.md)
filled in. Especially interested in:

- Non-Snapdragon SoCs (Exynos, Dimensity, Tensor)
- Devices with game-mode overlays (Samsung Game Booster, ASUS Game
  Genie, ROG Game Center) - tracking a known issue where their
  overlays block taps
- KernelSU and APatch users (Magisk is tested, the other two are
  code-path-supported but un-bench-tested)

No telemetry, no bundled vendor binaries (calls official installers).

---

## Hacker News (Show HN)

**Title**: `Show HN: Root.AICLI - installs AI coding CLIs into Termux on rooted Android`

**Body**:

I built a 25 KB Android app that fixes a problem I kept hitting on my
Ayn Odin 3 handheld: every time I wanted Claude Code or Codex working
in Termux, I had to redo the same dance of Bionic-vs-glibc detection,
SELinux MLS context relabeling, and Magisk mount-namespace gymnastics
to get the vendor's curl-pipe installer to work.

The app has eight buttons. Status checks what's installed. Four
install Claude Code, Codex, Antigravity, and Grok respectively. One
("Permanent Fix") writes a Magisk/KernelSU/APatch boot hook that
heals two recurring Termux failure modes that hit all rooted users
periodically (mode-600 .so files and dropped MLS categories from
package upgrades).

The install logic is open-source shell modules on disk, not in the
APK. Update the modules and you update what the buttons do; no APK
rebuild needed.

Notable design choices:

- No Compose, no Gradle, no androidx. Native View + LinearLayout +
  Runtime.exec. 25 KB APK that builds in 3 seconds with a 7-step
  shell pipeline (aapt2 + javac + d8 + apksigner).
- No telemetry, no analytics, no auto-network from the app itself.
  The only network traffic during use is the vendor's official
  installer that the user explicitly invokes.
- `su -mm` (mount-master) is required: Magisk gives apps an isolated
  mount namespace by default where `/data/data/<other-app>/`
  appears empty. Without -mm the install scripts can't see Termux's
  filesystem.

The repo has a five-minute writeup of the five non-obvious
Android/Termux interactions that this whole project exists to work
around: https://github.com/Crypt0Shmipt0/root-aicli/blob/main/docs/ARCHITECTURE.md

MIT, source + signed release: https://github.com/Crypt0Shmipt0/root-aicli

Feedback welcome, especially from anyone running rooted Android with
Termux.

---

## Twitter / X (one-shot)

```
Open-sourced Root.AICLI

25 KB Android app that installs the four big AI coding CLIs into Termux on rooted Android with one tap each:
- Claude Code
- OpenAI Codex
- Antigravity (agy)
- xAI Grok Build

Plus a boot hook that fixes the "Termux broke after pkg upgrade" problem.

MIT. No telemetry.

https://github.com/Crypt0Shmipt0/root-aicli
```

---

## Format notes

- Reddit prefers descriptive titles with the tool name + what it does
- XDA likes the `[APP][version][Root]` tag prefix
- HN prefers `Show HN:` prefix
- Twitter/X: lead with the noun, end with the link

**Avoid**:

- Posting identical copy to all venues in the same hour
- Linking the same screenshot repeatedly
- Bumping your own thread
- Replying to negative comments defensively (link to the FAQ instead)
