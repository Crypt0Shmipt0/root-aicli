# Troubleshooting

## The app crashes on launch

Look at logcat:

```sh
adb logcat -d | grep -E 'AndroidRuntime|FATAL' | grep tweaks
```

The most common cause is a stale install where `MainActivity.class` wasn't
included in `classes.dex`. Rebuild from source and reinstall.

## "tomer-tweaks: inaccessible or not found" (or similar)

You're hitting one of the five non-obvious Termux/Android interactions.
Read [ARCHITECTURE.md](./ARCHITECTURE.md) section "The five non-obvious
lessons." The fix is almost always one of:

1. `su -mm` not `su -c` (Magisk mount namespace)
2. Run as root, not `su <uid>` (SELinux context, not just POSIX UID)
3. `LD_LIBRARY_PATH=$PREFIX/lib $PREFIX/bin/bash <script>` (libc loader)
4. Invoke bash directly, not via the shebang (kernel exec from outside Termux)
5. Re-apply MLS contexts after writing under su (the boot persistence hook)

## Status shows "Termux NOT installed" but I have Termux

Termux from the Play Store has a different package signature and is
incompatible. You need the F-Droid build:
https://f-droid.org/packages/com.termux/

Uninstall the Play Store version completely first.

## Status shows "Root NOT working"

Open your root manager (Magisk, KernelSU, APatch). Find Root.AICLI in
the list of apps requesting root. Grant it. Make sure "Remember choice"
is enabled so it doesn't ask again.

## Claude Code installed but `claude` says "command not found" in Termux

This usually means the dispatcher symlink got written without Termux's
MLS context. The next launch of Termux can't see it.

Fix: tap **Permanent Fix** in the app once. It re-applies MLS to the
relevant paths and installs the boot hook so this doesn't happen again.

## Antigravity (agy) install fails with TCMalloc errors

The official Google installer doesn't work on Termux under proot because
TCMalloc assumes a 48-bit virtual address space and proot only gives it
39 bits. The wallentx fork (which Root.AICLI uses by default) fixes this
by patching TCMalloc's bitmask instructions for 39-bit VA.

If the wallentx install itself fails, file a bug at:
https://github.com/wallentx/antigravity-cli-termux

## Codex / Grok install fails on bare Termux

Both are likely to require glibc that Termux Bionic can't provide. Install
Alpine and retry:

```sh
pkg install proot-distro
proot-distro install alpine
```

Then tap **Install Codex** / **Install Grok** again. Root.AICLI will
auto-detect Alpine and route the install there.

## "su: inaccessible or not found" appears in the log

Your root manager is denying Root.AICLI. Open it and grant permission.
For Magisk specifically, this may be in Settings → SuperUser → Root.AICLI.

## I get permission prompts every time

In your root manager, find Root.AICLI and change from "Prompt" to
"Allow" or "Grant" (the wording varies by manager). Magisk has a
"Remember choice" checkbox on the prompt itself.

## After an update, nothing works

Tap **Permanent Fix** once after any major Termux update or Android OTA.
This re-applies MLS contexts and reinstalls the boot hook.

## Reporting a bug we don't cover

Include:

1. Full **Status** output (long-press the log pane to copy, or screenshot)
2. The action that failed and the entire log at the `[exit N]` line
3. Device, Android version, root manager version, Termux source

Open an issue at https://github.com/Crypt0Shmipt0/root-aicli/issues
