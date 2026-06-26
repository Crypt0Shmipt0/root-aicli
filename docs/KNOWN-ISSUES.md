# Known issues

Issues we know about but have not fixed yet, with the best available
workaround. PRs welcome.

## Game-mode overlay apps swallow touches

**Affected**: Ayn Odin 3 (GameAssistant), Samsung phones in Game
Booster mode, ASUS ROG phones in Game Genie mode, MediaTek devices
with Game Center.

**Symptom**: tapping Root.AICLI buttons does nothing. The log pane
stays empty. The activity is focused (you can confirm with
`dumpsys window | grep mCurrentFocus`) but tap events do not reach it.

**Root cause**: these overlay apps install a full-screen
`MAGNIFICATION_OVERLAY` window above the application z-order to draw
their HUD. On at least some configurations, that window also captures
touch events instead of passing them through.

**Workaround 1 (keyboard)**: connect a USB or Bluetooth keyboard, or
enable the on-screen keyboard's TAB key. Press TAB to advance focus
button by button (STATUS -> CLAUDE -> ANTIGRAVITY -> CODEX -> GROK ->
INSTALL ALL -> PERMANENT FIX -> CLEAR LOG). Press ENTER or DPAD_CENTER
to activate.

**Workaround 2 (temporarily disable the overlay)**:

```sh
adb shell "su -c 'pm disable com.odin.gameassistant'"   # Odin 3
# ... do your installs ...
adb shell "su -c 'pm enable com.odin.gameassistant'"
```

(Substitute your overlay app's package name.)

**Fix planned**: detect the overlay window and either prompt the user
to disable it or render Root.AICLI as a system overlay itself. Not
straightforward.

## Permanent Fix takes 30 to 90 seconds

**Symptom**: tapping PERMANENT FIX, log shows "applying once now..."
and then nothing for up to a minute and a half.

**Cause**: the boot hook sweeps SELinux contexts across all of
`$PREFIX` (bin, lib, libexec, etc, var) plus user home subdirs. That
is roughly 5000 files on a typical Termux. Each `chcon` is a syscall.

**Workaround**: wait. The exit will be 0 when it is done.

**Fix planned**: parallelize the chcon sweep, or use `restorecon` with
a file context spec instead of bare `chcon`.

## Grok's installer exits non-zero by design

**Symptom**: INSTALL GROK occasionally completes with what looks like
a success message ("Run 'grok' or 'agent' to get started!") but exit
code is 1.

**Cause**: xAI's installer tries to launch `grok` at the end as a
verification step. Under `su`, there is no controlling TTY, so the
launch fails with `bubbletea: error opening TTY`. The binary install
itself succeeded.

**Workaround**: we already handle this in v0.1.0+ by tolerating the
non-zero exit and verifying the binary exists afterward. If you see
exit 1 with a successful-looking message, run STATUS and confirm
grok shows up; it should.

## ~/.local/bin not on PATH after first install

**Symptom**: `command not found: codex` (or similar) in a fresh
Termux session after a successful install.

**Cause**: the official installers add a PATH export to `~/.profile`,
but Termux's bash does not source `~/.profile` automatically in
interactive mode.

**Workaround**: add to `~/.bashrc`:

```sh
export PATH="$HOME/.local/bin:$HOME/.grok/bin:$PATH"
```

Then `source ~/.bashrc`.

## "claude" command shows the Odin capability matrix instead of a version

**Affected**: original Tomer Tweaks test device (Ayn Odin 3 with the
on-device-stack briefing).

**Symptom**: `claude --version` from STATUS prints the dispatcher's
capability banner instead of the expected `2.1.x (Claude Code)`.

**Cause**: that device has a pre-existing custom claude dispatcher
from the Tomer Tweaks era that prepends a briefing to every claude
invocation. Community devices will not have this.

**Workaround**: not Root.AICLI's problem; will not affect anyone else.
Replace `$PREFIX/bin/claude` with the dispatcher Root.AICLI installs
if it bothers you.

## Magisk grant prompt occasionally not auto-granted on first tap

**Symptom**: tap a button, root prompt appears, tap Grant, but the
action does not run. Exit code shows 13 (EACCES).

**Cause**: Magisk's "Forever" allow rule is established only after
the user dismisses the dialog. If the queued exec happens before the
rule is persisted, it can be denied.

**Workaround**: tap the action again after the dialog dismisses. The
rule should be in place by then.

**Fix planned**: detect the deny and prompt the user to re-tap.

## My PR was closed without explanation

It was probably one of:

- No real-device test report in the PR description
- New CLI added but no entry in CHANGELOG / README CLI table /
  CLI-REFERENCE.md / 00-detect.sh
- Code adds external runtime dependencies (Compose, androidx, etc.)
- Behavior breaks an existing tested CLI

We try to comment on these, but if a PR sat for a long time without
movement we sometimes close to keep the queue tidy. Re-open with the
missing pieces and we will look again.
