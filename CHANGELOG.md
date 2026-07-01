# Changelog

All notable changes to Root.AICLI will be documented in this file. Format
follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), versioning
follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.1] - 2026-07-01

### Fixed
- **Claude dispatcher shadow.** A native `claude` self-update (or a bare-Termux
  install) drops a `~/.local/bin/claude` that sits ahead of `$PREFIX/bin` in
  PATH and silently shadows the Alpine dispatcher, so `claude` breaks while
  every other CLI keeps working. The dispatcher is now written to all three
  entry points (`~/.local/bin`, `~/bin`, `$PREFIX/bin`), kept as a canonical
  copy under `$PREFIX/libexec/root-aicli/`, reasserted on every boot by the
  persistence hook, and healed on each login shell by a new
  `etc/profile.d/root-aicli-claude.sh` guard (zero-gap).

## [0.1.0] - 2026-06-26

### Added
- Initial release.
- One-tap installer Android app for AI coding CLIs in Termux on rooted Android.
- Supported CLIs:
  - **Claude Code** (Anthropic) - Alpine path for current versions, bare
    Termux pinned to 2.1.112 for Bionic devices.
  - **Antigravity (agy)** (Google) - via the wallentx Termux fork with the
    TCMalloc 39-bit-VA patch.
  - **OpenAI Codex CLI** - native arm64-musl binary, runs in bare Termux.
  - **xAI Grok Build CLI** - official installer, Alpine fallback for
    Bionic-incompatible builds.
- Auto-detection of:
  - Termux UID (computes SELinux MLS categories at runtime, no hardcoded
    values).
  - Root manager: Magisk / KernelSU / APatch.
  - Runtime preference: Alpine proot-distro when available, bare Termux
    otherwise.
  - Existing CLI installs and versions.
- **Permanent Fix** action installs a root-manager-appropriate boot hook
  that re-applies Termux SELinux MLS contexts on every boot, healing the
  package-upgrade-strips-MLS pattern that bricks Termux periodically.
  Also `chmod 644` any `.so` files that ended up at mode 600 (a separate
  Termux package-management quirk).
- Gradle-free, Compose-free Android build pipeline (`aapt2` + `javac` +
  `d8` + `apksigner`). Reproducible APK in ~3 seconds.
- GitHub Actions CI for reproducible builds and signed release attachments.
- F-Droid fastlane metadata.

### Known limitations
- Tested on Ayn Odin 3 (Android 15) so far. Other devices welcome.
- Devices with overlay apps (game enhancement modes like Odin's
  GameAssistant, Samsung Game Booster, etc.) may block touches to
  Root.AICLI buttons. Workaround: use TAB navigation (keyboard) or
  disable the overlay app before tapping. Tracked in known issues.

[Unreleased]: https://github.com/Crypt0Shmipt0/root-aicli/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/Crypt0Shmipt0/root-aicli/releases/tag/v0.1.0
