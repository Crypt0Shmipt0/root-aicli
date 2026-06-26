# Installation Guide

Three install paths, in order of preference for most users.

## Path A - sideload the signed APK from GitHub Releases (recommended)

1. On your phone, open https://github.com/Crypt0Shmipt0/root-aicli/releases/latest
2. Under "Assets", download `RootAICLI.apk`.
3. Tap the downloaded file. If Android warns about unknown sources, allow
   installation **for this app only**, then proceed.
4. Open Root.AICLI from the app drawer.

The APK is signed with the project debug keystore committed in the repo
so anyone who clones can produce a byte-identical APK. The signature is
not a trust boundary by design.

## Path B - install via F-Droid

(Pending F-Droid review; estimated 2 to 6 weeks after the first tagged
release.)

Once accepted:

1. Open F-Droid.
2. Search for "Root.AICLI" (or browse the "Development" category).
3. Tap Install.
4. F-Droid handles updates automatically.

## Path C - build from source

You will need a Mac, Linux, or WSL host with:

- Bash
- Python 3 with the Pillow package (`pip install Pillow`)
- OpenJDK 17 (`brew install openjdk@17` on macOS,
  `sudo apt install openjdk-17-jdk` on Debian/Ubuntu)
- Android command-line tools and SDK platform 34 + build-tools 34.0.0

### Set up the Android SDK (one time)

macOS:

```sh
mkdir -p ~/Library/Android/sdk/cmdline-tools
cd ~/Library/Android/sdk/cmdline-tools
curl -sSL -o cmdline-tools.zip https://dl.google.com/android/repository/commandlinetools-mac-11076708_latest.zip
unzip -q cmdline-tools.zip && mv cmdline-tools latest && rm cmdline-tools.zip
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$ANDROID_HOME/cmdline-tools/latest/bin:$PATH
yes | sdkmanager --licenses
sdkmanager "platforms;android-34" "build-tools;34.0.0" "platform-tools"
```

Linux:

```sh
mkdir -p ~/Android/Sdk/cmdline-tools
cd ~/Android/Sdk/cmdline-tools
curl -sSL -o cmdline-tools.zip https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip
unzip -q cmdline-tools.zip && mv cmdline-tools latest && rm cmdline-tools.zip
export ANDROID_HOME=$HOME/Android/Sdk
export PATH=$ANDROID_HOME/cmdline-tools/latest/bin:$PATH
yes | sdkmanager --licenses
sdkmanager "platforms;android-34" "build-tools;34.0.0" "platform-tools"
```

### Build the APK

```sh
git clone https://github.com/Crypt0Shmipt0/root-aicli
cd root-aicli/android-app
./build.sh
```

The signed APK lands at `build/RootAICLI.apk`. Roughly 25 KB, builds
in about 3 seconds.

### Install on a connected device

```sh
adb install -r build/RootAICLI.apk
```

Or use the included helper:

```sh
./install-apk.sh
```

## First-launch setup

Whichever path you used:

1. Open Root.AICLI from the app drawer.
2. Tap **STATUS**. Your root manager will pop a su prompt. Grant it
   with "Remember" / "Forever" enabled.
3. Confirm the status log shows green `[+]` for Termux installed, Root
   manager detected, and runtime preference (alpine or bionic).
4. Tap **PERMANENT FIX** once. This installs a boot-time hook that
   prevents the recurring Termux-breaks-after-pkg-upgrade problem.

You are now ready to install CLIs. See
[Quickstart](./QUICKSTART.md#step-4---install-your-first-cli) for the
recommended first install, or jump straight to the
[CLI Reference](./CLI-REFERENCE.md) for per-CLI details.

## Uninstall

From Android Settings -> Apps -> Root.AICLI -> Uninstall.

The CLIs themselves stay installed in Termux. To remove them:

- Claude Code: `npm uninstall -g @anthropic-ai/claude-code` (bare
  Termux) or remove via `proot-distro login alpine -- npm uninstall -g
  @anthropic-ai/claude-code` (Alpine path).
- Codex: `rm -rf ~/.codex ~/.local/bin/codex ~/.local/bin/codex-*`
- agy: `rm -rf ~/.local/bin/agy ~/.local/bin/agy.bin ~/.local/bin/agy.va39`
- Grok: `rm -rf ~/.grok ~/.local/bin/grok` (bare) or
  `proot-distro login alpine -- rm -rf /root/.grok /usr/local/bin/grok`
  (Alpine).

The boot persistence hook can be removed with:

```sh
su -c "rm -f /data/adb/service.d/root-aicli-persist.sh"   # Magisk
su -c "rm -f /data/adb/post-fs-data.d/root-aicli-persist.sh"  # KernelSU/APatch
```
