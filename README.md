# Root.AICLI

> One-tap installer for AI coding CLIs on rooted Android Termux.

Root.AICLI is a small Android app that installs and repairs the major AI
coding command-line clients inside Termux on rooted devices, with no manual
shell wrangling. It auto-detects your environment, picks the right install
path for each CLI, and applies the SELinux MLS gymnastics needed to keep
Termux from breaking on the next reboot.

Supported CLIs:

| CLI | Vendor | Install path | Auth |
|---|---|---|---|
| **Claude Code** | Anthropic | Alpine (current) or bare Termux pinned to 2.1.112 | OAuth or `ANTHROPIC_API_KEY` |
| **Antigravity (agy)** | Google | Wallentx Termux fork (Bionic bridge + TCMalloc fix) | Google OAuth |
| **Codex CLI** | OpenAI | Native musl arm64 binary on bare Termux | OAuth or `OPENAI_API_KEY` |
| **Grok Build CLI** | xAI | Native arm64 on bare Termux, Alpine fallback | OAuth or `XAI_API_KEY` |

## Why this exists

Every AI vendor ships a curl-pipe-to-bash installer that assumes a "normal"
Linux. Termux on Android is not normal:

- The libc is **Bionic**, not glibc, so glibc-only binaries refuse to exec.
- Files written under `su` come back without the Termux app's **SELinux MLS
  categories**, and the next Termux session gets `exec: Operation not
  permitted`.
- Magisk's `su` runs in an **isolated mount namespace** by default, so
  installer scripts can't see Termux's filesystem unless invoked with `su -mm`.
- Each CLI vendor solves "Android arm64" differently: some ship musl, some
  ship glibc, some hand it to community forks.

Root.AICLI handles all of this. You tap a button, it figures out which path
applies to your device, and runs the right install.

## Requirements

- **Rooted Android 8+** (Magisk, KernelSU, or APatch).
- **Termux** installed from F-Droid (`com.termux` package, F-Droid build).
  The Play Store build is signature-incompatible with Termux companion apps.
- **Optional but recommended**: Termux:Boot, Termux:Widget, Termux:API from
  the same source.
- **Optional**: `proot-distro install alpine` for the latest Claude Code
  (versions 2.1.113+ require glibc/musl).

## Quick start

1. Install Termux from F-Droid: https://f-droid.org/packages/com.termux/
2. Download `RootAICLI.apk` from the [releases page](https://github.com/Crypt0Shmipt0/root-aicli/releases) and install it.
3. Open **Root.AICLI**. On first tap, your root manager prompts for su access.
   Grant and remember.
4. Tap **Status** to see what's installed.
5. Tap any CLI button to install it. Wait for `[exit 0]`.
6. Tap **Permanent Fix** once to install the boot-time persistence hook.
   This re-applies Termux SELinux contexts on every boot so auto-updates
   don't break Termux exec.
7. Open Termux and run the CLI (e.g. `claude`, `codex`, `agy`, `grok`).
   Authenticate per the prompts shown in the app.

## How it works

The APK is a thin Java shell. Every button taps fires `su -mm -c <bash + module>`
which runs one of the install scripts under `modules/` with the global mount
namespace (so the APK's su can see Termux's private storage at
`/data/data/com.termux/files/`). Termux's own bash is invoked with
`LD_LIBRARY_PATH=$PREFIX/lib` so it can load its libc.

Files:

```
root-aicli/
├── android-app/          The APK (Java + native View, no Gradle, no Compose)
├── modules/              One install script per CLI plus detect + persistence
├── lib/common.sh         Shared helpers: UID detection, MLS computation, etc.
├── root-aicli            The Termux CLI front-end (also callable from the APK)
├── docs/                 Architecture + troubleshooting
├── fastlane/             F-Droid metadata
└── .github/workflows/    Reproducible APK CI
```

## Authentication after install

Each CLI has its own first-run auth. Root.AICLI never touches credentials.

| CLI | Headless option | Interactive |
|---|---|---|
| Claude Code | `export ANTHROPIC_API_KEY=...` or `claude setup-token` | `claude` (browser OAuth) |
| Antigravity (agy) | (none; Google OAuth only) | `agy login` |
| Codex | `export OPENAI_API_KEY=...` | `codex` (browser OAuth) |
| Grok Build | `export XAI_API_KEY=...` | `grok` (browser OAuth) |

If you're on a handheld with no easy browser, use the headless env-var path.

## Building from source

You need a Mac or Linux with `bash`, `python3`+`Pillow`, and the Android SDK
command-line tools. From the project root:

```sh
brew install openjdk@17
mkdir -p ~/Library/Android/sdk/cmdline-tools
cd ~/Library/Android/sdk/cmdline-tools
curl -sSL -o cmdline-tools.zip https://dl.google.com/android/repository/commandlinetools-mac-11076708_latest.zip
unzip -q cmdline-tools.zip && mv cmdline-tools latest && rm cmdline-tools.zip
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$ANDROID_HOME/cmdline-tools/latest/bin:$PATH
yes | sdkmanager --licenses
sdkmanager "platforms;android-34" "build-tools;34.0.0" "platform-tools"
```

Then:

```sh
cd android-app
./build.sh           # produces build/RootAICLI.apk
./install-apk.sh     # ADB install on the first connected device
```

CI does the same thing reproducibly. See `.github/workflows/build.yml`.

## License

MIT. See [LICENSE](./LICENSE).

Root.AICLI **does not redistribute** the AI CLI binaries themselves. It only
orchestrates the official upstream installers. Each CLI is governed by its
own vendor's terms.

## Credits

- The mount-master + MLS-context debugging story that made this app possible
  was originally worked out for the **Ayn Odin 3** in a project called
  Tomer Tweaks. Root.AICLI is the open-source generalization.
- The **wallentx** fork of Antigravity is what makes agy work on Termux at
  all. Without their TCMalloc 39-bit-VA patch, agy refuses to start under
  proot. https://github.com/wallentx/antigravity-cli-termux

## Contributing

See [CONTRIBUTING.md](./docs/CONTRIBUTING.md). PRs welcome for new CLIs
(Aider, Continue, llm, etc.), bug fixes, and translations.
