#!/data/data/com.termux/files/usr/bin/env bash
# Install or repair Anthropic's Claude Code CLI.
#
# Path A (Alpine present): install the latest Claude Code in Alpine via the
# official native installer. Works because Alpine is musl and the installer
# ships a Linux-arm64-musl binary.
#
# Path B (bare Termux only): pin to @anthropic-ai/claude-code@2.1.112, the
# last JavaScript-based release that runs under Bionic libc. Versions 2.1.113+
# ship a glibc-only binary that Android's Bionic kernel will not exec.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/../lib/common.sh"

banner "Install / repair Claude Code"

require_root

PREF=$(detect_runtime_preference)

if [ "$PREF" = "alpine" ]; then
  # --- Path A: Alpine ---------------------------------------------------------
  log_info "Alpine container present; installing latest Claude Code there."
  alpine_run "
    set -eu
    apk update >/dev/null 2>&1 || true
    apk add --no-cache nodejs npm curl ca-certificates bash libgcc libstdc++ ripgrep >/dev/null
    # Anthropic native installer expects bash, NOT busybox sh.
    curl -fsSL https://claude.ai/install.sh | bash || {
      echo '[alpine] native installer failed; falling back to npm'
      rm -f /usr/local/bin/claude /usr/local/bin/claude-* 2>/dev/null || true
      npm install -g --force @anthropic-ai/claude-code
    }
    if [ -x \"\$HOME/.local/bin/claude\" ]; then
      \"\$HOME/.local/bin/claude\" --version
    elif command -v claude >/dev/null; then
      claude --version
    else
      echo 'WARNING: claude not on PATH after install'; exit 1
    fi
  "

  # --- Termux dispatcher so 'claude' in Termux forwards into Alpine ----------
  # Write the dispatcher to EVERY entry point a native `claude` install can
  # occupy (~/.local/bin, ~/bin, $PREFIX/bin) so it can't be shadowed in PATH,
  # plus a login-shell guard that reasserts it after a `claude` self-update.
  log_info "Installing Termux -> Alpine dispatcher (all entry points + session guard)"
  install_claude_dispatcher
  install_claude_session_guard
else
  # --- Path B: bare Termux Bionic (Claude 2.1.112 pin) -----------------------
  log_info "Bare Termux Bionic: pinning Claude Code to v2.1.112 (last Bionic-compatible)."
  log_warn "For the latest Claude Code, install Alpine via 'pkg install proot-distro && proot-distro install alpine'."
  if ! termux_run "command -v npm" >/dev/null 2>&1; then
    log_info "Installing nodejs in Termux..."
    termux_run "pkg install -y nodejs"
  fi
  termux_run "
    set -eu
    npm uninstall -g @anthropic-ai/claude-code 2>/dev/null || true
    rm -f \$PREFIX/bin/claude 2>/dev/null || true
    npm install -g --force @anthropic-ai/claude-code@2.1.112
    claude --version || true
  "
fi

# Re-apply MLS contexts so Termux can read what we just wrote under su.
log_info "Re-applying Termux MLS contexts..."
apply_termux_mls "$TERMUX_PREFIX/bin"
apply_termux_mls "$TERMUX_HOME/.local"
[ "$PREF" = "alpine" ] && apply_termux_mls "$ALPINE_ROOTFS/root/.local" || true

log_ok "Claude Code install complete."
echo
log_info "Auth: open a Termux shell and run 'claude' to OAuth via browser,"
log_info "      OR set ANTHROPIC_API_KEY (Console API key),"
log_info "      OR run 'claude setup-token' for a 1-year OAuth token."
