# Architecture

Root.AICLI is split into three layers:

```
┌────────────────────────────────────┐
│   Android APK                      │   dev.rootaicli.MainActivity
│   (Java + native View, 25 KB)      │   button surface + log streaming
└──────────────┬─────────────────────┘
               │  Runtime.exec("su -mm -c <cmd>")
               ▼
┌────────────────────────────────────┐
│   Bash dispatcher                  │   ~/root-aicli/root-aicli
│   (single entry point)             │   resolves symlinks, dispatches to
└──────────────┬─────────────────────┘   modules
               │  bash modules/NN-*.sh
               ▼
┌────────────────────────────────────┐
│   Install modules                  │   ~/root-aicli/modules/
│   (one per CLI + detect + persist) │   call termux_run / alpine_run
└────────────────────────────────────┘
```

## The five non-obvious lessons baked in

These are tribal-knowledge fixes that took real debugging on the Odin 3
during the prototype phase. Each one is now encoded in `lib/common.sh` or a
module so users don't have to learn them.

### 1. Magisk's su uses an isolated mount namespace by default

`su -c "..."` from an app context gives you root, but it gives you root in a
namespace where `/data/data/<other-app>/` looks empty. You'll see
`/data/data/com.termux/files/usr/bin/bash: No such file or directory` even
though the file is right there.

**Fix:** invoke `su -mm` (mount-master) which uses the global namespace.

### 2. Switching UID via `su <uid>` does not switch SELinux context

`su u0_a211 -c "..."` changes the POSIX UID but the resulting process stays
in the `u:r:su:s0` SELinux domain. That domain is denied access to
`/data/data/com.termux/`. You get "No such file or directory" again, this
time as Android's stock disguise for permission denied.

**Fix:** stay as root and access Termux paths directly. Root in
`u:r:magisk:s0` has full access regardless of MLS.

### 3. Termux's bash needs LD_LIBRARY_PATH to load its libc

`/data/data/com.termux/files/usr/bin/bash` is linked against Termux's own
Bionic libc at a non-standard sysroot. Outside a Termux shell session you
have to set `LD_LIBRARY_PATH=$PREFIX/lib` or the dynamic loader fails.

### 4. The shebang chain `#!/usr/bin/env bash` does not work from outside Termux

When the kernel reads the shebang, it doesn't inherit any of the caller's
environment. `env` runs but can't find `bash` on the system PATH because
Termux's `bash` is at `$PREFIX/bin/bash`, not `/usr/bin/bash`.

**Fix:** invoke `$PREFIX/bin/bash <script>` directly so the kernel exec's
bash with the script as argv[1], bypassing the shebang lookup.

### 5. Files written under su come back without Termux's MLS categories

Every Android app gets a SELinux context like
`u:r:untrusted_app_31:s0:c<low>,c<high+256>,c512,c768` derived from its UID.
Files inside `/data/data/<pkg>/` carry the matching `app_data_file` context.
When `su` (which has no categories) writes a file there, the file lands
without categories, and the next time the app reads it, MLS blocks the read:
`exec: Operation not permitted`.

**Fix:** after every write under su, re-`chcon` the touched paths with the
detected Termux MLS context. The persistence module installs a boot hook
that does this automatically every time the device starts up.

The MLS formula is exact:

```
appid = uid - 10000
low   = appid % 256
high  = appid / 256
ctx   = u:object_r:app_data_file:s0:c<low>,c<256+high>,c512,c768
```

## Why no Gradle / Kotlin / Compose

The APK is 25 KB. The build is a 7-step shell pipeline (`aapt2` → `javac`
→ `d8` → `aapt2 link` → `zip` → `zipalign` → `apksigner`) that takes ~3
seconds on a modern laptop. Adding Gradle would pull in ~150 MB of build
deps and a 30-second cold build. Adding Compose would pull 8 MB of
androidx into the final APK and require either Gradle or a much messier
direct build.

For six buttons and a log pane, native View + LinearLayout is the right
call. The build is also reproducible by anyone with `openjdk@17` and the
Android SDK build-tools, with no version pinning headaches.

## Why no in-app credentials handling

Each CLI's vendor handles auth differently (OAuth browser, API key env
var, device code flow). Root.AICLI never touches credentials. After
install, the user authenticates by either:

- Setting `ANTHROPIC_API_KEY` / `OPENAI_API_KEY` / `XAI_API_KEY` in their
  Termux shell rc (headless path), or
- Running the CLI for the first time and following its OAuth flow
  (interactive path).

The advantage: no credential code paths in our APK means no surface area
for credential leaks, no vendor TOS concerns about wrapping their auth,
and no maintenance when a vendor changes their OAuth flow.
