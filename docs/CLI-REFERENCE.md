# CLI Reference

What each install action does, how to authenticate, and how to get past
the most common first-run paper cuts.

## Claude Code (Anthropic)

**Button**: `INSTALL CLAUDE CODE`

**Install path**:

- If Alpine proot-distro is present, Claude Code is installed inside
  Alpine (current versions; the binary is glibc/musl).
- If only bare Termux, Claude Code is pinned to version **2.1.112**
  because versions 2.1.113 and later require glibc that Termux's
  Bionic libc cannot provide.

**First run**:

```sh
claude
```

If you have a graphical browser available, this opens an OAuth flow.

**Headless auth (handheld-friendly)**:

Option 1 - API key from the Anthropic Console:

```sh
export ANTHROPIC_API_KEY="sk-ant-..."   # from https://console.anthropic.com
```

Add the export to `~/.bashrc` to persist it.

Option 2 - one-year OAuth token from another device:

On a desktop with a browser, run:

```sh
claude setup-token
```

That prints a `CLAUDE_CODE_OAUTH_TOKEN` value. On your phone:

```sh
export CLAUDE_CODE_OAUTH_TOKEN="..."
```

Add to `~/.bashrc`.

**Updates**: Claude Code self-updates in the background by default.
The Permanent Fix boot hook prevents the auto-update from breaking
Termux MLS (which it used to do every time before this app existed).

**Docs**: https://code.claude.com

## Antigravity (agy) - Google

**Button**: `INSTALL ANTIGRAVITY`

**Install path**: Always uses the
[wallentx Termux fork](https://github.com/wallentx/antigravity-cli-termux).
The fork:

- Bundles a Bionic-to-glibc bridge so the binary runs on Termux's libc.
- Includes the TCMalloc 39-bit-VA patch needed for any proot or
  emulator-VA scenario.
- Self-updates from upstream Antigravity releases.

The official Google installer is glibc-only and refuses to install
under Termux's Bionic; that is why we use the fork.

**First run**:

```sh
agy login
```

This opens a Google sign-in URL. On a handheld, copy the URL with your
volume keys (or `xsel`), open it on a desktop, sign in, paste the
returned authorization code back into the agy prompt.

**Headless auth**: not supported. Google does not offer an API-key
auth path for agy. If you need fully headless, use one of the other
CLIs.

**Updates**: `agy update` self-updates from the wallentx GitHub
release feed.

**Docs**: https://github.com/wallentx/antigravity-cli-termux

## OpenAI Codex CLI

**Button**: `INSTALL CODEX`

**Install path**: Always uses the
[official OpenAI installer](https://github.com/openai/codex)
(`https://chatgpt.com/codex/install.sh`). The binary is Rust, native
linux-arm64-musl, and runs in bare Termux without an Alpine proot.

The binary lands at `~/.local/bin/codex`. If `~/.local/bin` is not on
your PATH yet, the installer adds an export to `~/.profile`.

**First run**:

```sh
codex
```

By default Codex prompts you to sign in with your ChatGPT account
(OAuth via browser).

**Headless auth**:

```sh
export OPENAI_API_KEY="sk-..."
```

Get the key from https://platform.openai.com/api-keys. Add the export
to `~/.bashrc`.

**Updates**: re-running the installer pulls the latest release.
Run **INSTALL CODEX** again from Root.AICLI to update.

**Docs**: https://github.com/openai/codex

## xAI Grok Build CLI

**Button**: `INSTALL GROK`

**Install path**:

- If Alpine is present, installs in Alpine via the official xAI
  installer at `https://x.ai/cli/install.sh`. A small dispatcher at
  `$PREFIX/bin/grok` forwards `grok` invocations into Alpine.
- If only bare Termux, runs the same installer directly. This may
  fail if xAI's binary is glibc-only on your build; the failure is
  surfaced clearly and you can `pkg install proot-distro` and re-run.

The binary lands at `~/.grok/bin/grok` (or
`/root/.grok/bin/grok` inside Alpine).

**First run**:

```sh
grok
```

Browser OAuth via xAI.

**Headless auth**:

```sh
export XAI_API_KEY="xai-..."
```

Get the key from https://console.x.ai. Add the export to `~/.bashrc`.

**Updates**: re-run the installer (tap **INSTALL GROK** again).

**Docs**: https://docs.x.ai/build/cli/

## Common patterns

### Adding env-var auth to your shell rc

Edit `~/.bashrc` (or `~/.zshrc` if you use zsh in Termux). Add:

```sh
export ANTHROPIC_API_KEY="..."
export OPENAI_API_KEY="..."
export XAI_API_KEY="..."
```

Then either restart your Termux session or `source ~/.bashrc`.

### Updating all CLIs

Open Root.AICLI and tap **INSTALL ALL**. This chains all four installs
in sequence. Roughly 3 to 5 minutes total.

### Checking what is installed

Tap **STATUS** in the app. The log shows each detected CLI with its
version, or `not installed` if missing.

From a Termux shell:

```sh
claude --version
agy --version
codex --version
grok --version
```

### "command not found" after install

This usually means `~/.local/bin` or `~/.grok/bin` is not on your PATH
yet. Add to `~/.bashrc`:

```sh
export PATH="$HOME/.local/bin:$HOME/.grok/bin:$PATH"
```

Then `source ~/.bashrc`.

### Permanent Fix did not auto-run on boot

Check that the hook script is in your root manager's boot directory:

| Root manager | Hook path |
|---|---|
| Magisk | `/data/adb/service.d/root-aicli-persist.sh` |
| KernelSU | `/data/adb/post-fs-data.d/root-aicli-persist.sh` |
| APatch | `/data/adb/post-fs-data.d/root-aicli-persist.sh` |

Verify with:

```sh
su -c "ls -la /data/adb/service.d/root-aicli-persist.sh"
```

If missing, re-tap **PERMANENT FIX** in Root.AICLI.
