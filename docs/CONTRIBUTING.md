# Contributing to Root.AICLI

Thanks for considering a contribution.

## Quick orientation

Read [ARCHITECTURE.md](./ARCHITECTURE.md) first. There are five
non-obvious Android / Termux interactions that the app has already
encoded; trying to add a feature without knowing them will lead to
fights with `su`, SELinux, and mount namespaces.

## Adding a new CLI

To add a new CLI (e.g. Aider, Continue, llm, claude-flow):

1. Create `modules/24-yourname.sh` (next free number). Copy the structure
   of `22-codex.sh` and adjust:
   - Where the installer comes from (curl URL, npm package, etc.)
   - Whether it needs Bionic vs Alpine (`detect_runtime_preference`)
   - Auth flow hint at the bottom

2. Add a button in `android-app/res/layout/activity_main.xml`. Pattern
   after the existing CLI buttons. Add a string in `strings.xml`.

3. Wire the button in `android-app/src/dev/rootaicli/MainActivity.java`
   with one new line:

   ```java
   bind(R.id.btn_yourname, "yourname");
   ```

4. Add a case in `root-aicli` dispatcher:

   ```sh
   yourname) run_module 24-yourname.sh ;;
   ```

5. Add the CLI to the table in `README.md` and `00-detect.sh`.

6. Test on real hardware. PRs without a test report from a real rooted
   device will be asked for one.

## Adding root-manager support

Magisk, KernelSU, and APatch are supported. To add support for another
(e.g. SukiSU, Brevent-su):

1. Add a detection branch in `lib/common.sh::detect_root_manager`.
2. Add a service.d-equivalent path in `detect_service_dir`.
3. Test the `permanent` action and confirm the hook fires on reboot.

## Coding conventions

- **bash:** `set -euo pipefail` at the top, source `lib/common.sh`,
  prefer `log_info` / `log_ok` / `log_warn` / `log_err` over raw echo.
- **Java:** native View, no androidx, no Compose, no third-party deps.
  Keep MainActivity flat and readable.
- **No bundled binaries.** Every CLI install must call the official
  upstream installer. We never ship vendor binaries inside this repo
  or APK.
- **No analytics, telemetry, or auto-network calls.** The app does not
  contact any server unless the user explicitly triggers an install.
- **No em dashes.** Use double hyphens (--) or parentheses instead.

## Testing

The minimum bar for a PR:

1. The APK builds via `android-app/build.sh` with no errors.
2. The new action runs to `[exit 0]` on a real rooted device.
3. A screenshot of the action's success in the in-app log pane.

A short test report in the PR description that lists:

- Device + Android version
- Root manager + version
- Termux build (F-Droid, GitHub debug, etc.)
- Which modules you ran and what they printed

## Reporting bugs

Include:

- Your `Status` output (paste the full log)
- The action that failed and the log pane contents at the `[exit N]` line
- Your root manager + Android version

Bug reports that say "didn't work" without these will be closed and
re-opened when the information arrives.

## Code of conduct

Be kind. Disagree on technical merits. The maintainers reserve the right
to remove anyone who makes the community worse to be in.
