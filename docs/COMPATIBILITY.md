# Compatibility matrix

What we have tested. PRs to extend this list with new device reports
welcome.

## Android versions

| Version | API | Status | Notes |
|---|---|---|---|
| 8.0 (Oreo) | 26 | Supported (min) | Compiles, runs; not yet bench-tested |
| 9 to 13 | 28 to 33 | Supported | Should work; awaiting community reports |
| 14 | 34 | Supported, build target | Smoke-tested in CI |
| 15 | 35 | Supported, primary test target | Tested daily on Ayn Odin 3 |

## Root managers

| Manager | Version | Status | Notes |
|---|---|---|---|
| Magisk | v25 to v30 | Tested | Primary development target |
| KernelSU | v0.7+ | Code path supported, awaiting reports | `post-fs-data.d` boot hook |
| APatch | latest | Code path supported, awaiting reports | `post-fs-data.d` boot hook |
| SukiSU, other forks | n/a | Should work if they expose `su -mm` | File an issue |

## Termux source

| Source | Status | Notes |
|---|---|---|
| F-Droid `com.termux` | **Required** | The only signature that works with companion apps |
| GitHub debug builds (`db86cf3c`) | Works | Used during heavy development; not for end users |
| Play Store | **Will not work** | Different signature, frozen on older Android |

## Termux companion apps

Not required, but recommended:

| App | Why |
|---|---|
| Termux:Boot | Auto-start sshd after reboot. STATUS reports presence. |
| Termux:Widget | Homescreen shortcuts for any CLI. Useful but unrelated. |
| Termux:API | `termux-toast`, `termux-clipboard-set`, etc. Several CLIs benefit. |

## Devices

Community reports we have so far. Add yours by filing an issue with
the device, Android version, root manager, and the full STATUS output.

| Device | Android | Root | Outcome | Notes |
|---|---|---|---|---|
| Ayn Odin 3 (sun) | 15 | Magisk v30.7 | All 4 CLIs install, Permanent Fix works | Primary dev device. GameAssistant overlay blocks touches; use TAB nav or disable overlay. |

(Want yours listed? See `Reporting your device` below.)

## Hardware architectures

| Arch | Status |
|---|---|
| `aarch64` / `arm64` | **Primary target.** All four vendor CLIs ship arm64 binaries. |
| `armv7` / `arm32` | Untested. Some CLIs do not ship 32-bit. |
| `x86_64` | Untested. Should work for emulators (Bluestacks, Android Studio AVD). |

## Reporting your device

Open https://github.com/Crypt0Shmipt0/root-aicli/issues/new?template=device-report.md

Include:

1. Manufacturer + model + codename
2. Android version + security patch level
3. Root manager + version
4. Termux source + version
5. The full output of tapping **STATUS** in Root.AICLI
6. The full output of any install button you tested
7. Anything weird (overlay apps, custom Termux setup, etc.)

We will add successful reports to the table above, and triage failures
as bugs.
