#!/data/data/com.termux/files/usr/bin/env bash
# Detect the environment and print a structured report.
# Used as a pre-flight check before any install action and as the back-end
# for the APK's STATUS button.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/../lib/common.sh"

banner "Root.AICLI: environment detection"

# --- Termux installed? -------------------------------------------------------
if [ -d /data/data/com.termux/files ]; then
  log_ok "Termux installed"
  log_info "  uid:    $(detect_termux_uid)"
  log_info "  user:   $(detect_termux_user)"
  log_info "  MLS:    $(detect_termux_mls_context)"
else
  log_err "Termux NOT installed. Install from F-Droid:"
  log_err "  https://f-droid.org/packages/com.termux/"
  exit 2
fi

# --- Root --------------------------------------------------------------------
case "$(detect_root_manager)" in
  magisk)   log_ok "Root manager: Magisk" ;;
  kernelsu) log_ok "Root manager: KernelSU" ;;
  apatch)   log_ok "Root manager: APatch" ;;
  unknown)  log_warn "Root manager: unknown (Magisk/KernelSU/APatch directories not found)" ;;
esac
if su -c 'id' 2>/dev/null | grep -q 'uid=0'; then
  log_ok "su -c id: uid=0 (root works)"
else
  log_err "Root NOT working. Grant Root.AICLI root permission in your root manager."
fi

# --- Runtime preference ------------------------------------------------------
PREF=$(detect_runtime_preference)
log_ok "Runtime preference: $PREF"
if [ "$PREF" = "alpine" ]; then
  log_info "  Alpine rootfs at $ALPINE_ROOTFS"
  log_info "  Used for: Claude Code (current), and CLIs that need glibc/musl"
else
  log_info "  Bare Termux (Bionic). Used for: Codex, agy, Grok native binaries."
  log_info "  Claude Code will be pinned to v2.1.112 (last Bionic-compatible)."
fi

# --- CLI install state -------------------------------------------------------
echo
log_info "Installed CLIs:"

check_cli() {
  local name=$1 cmd=$2 path=$3
  local found=""
  # Check the canonical absolute path first (file or symlink we expect)
  if [ -e "$path" ]; then found="$path"
  # Fall back to PATH lookup inside Termux env (including ~/.local/bin)
  elif termux_run "PATH=\$HOME/.local/bin:\$HOME/.grok/bin:\$PATH command -v $cmd" >/dev/null 2>&1; then
    found=$(termux_run "PATH=\$HOME/.local/bin:\$HOME/.grok/bin:\$PATH command -v $cmd" 2>/dev/null)
  fi
  if [ -n "$found" ]; then
    # Get version, strip ANSI escapes and CR
    local ver
    ver=$(termux_run "PATH=\$HOME/.local/bin:\$HOME/.grok/bin:\$PATH '$found' --version 2>/dev/null | head -1" 2>/dev/null \
          | sed -E 's/\x1b\[[0-9;]*[a-zA-Z]//g' \
          | tr -d '\r')
    log_ok "  $name: ${ver:-installed (version unknown)}"
  else
    log_warn "  $name: not installed"
  fi
}

check_cli "Claude Code"      claude  "$TERMUX_PREFIX/bin/claude"
check_cli "Antigravity (agy)" agy    "$TERMUX_HOME/.local/bin/agy"
check_cli "OpenAI Codex"     codex   "$TERMUX_HOME/.local/bin/codex"
check_cli "xAI Grok Build"   grok    "$TERMUX_HOME/.grok/bin/grok"

# --- Boot persistence --------------------------------------------------------
echo
SERVICE_DIR=$(detect_service_dir)
if [ -n "$SERVICE_DIR" ] && [ -f "$SERVICE_DIR/root-aicli-persist.sh" ]; then
  log_ok "Boot persistence hook: $SERVICE_DIR/root-aicli-persist.sh"
else
  log_warn "Boot persistence hook NOT installed. Run: Root.AICLI -> Permanent Fix"
fi

# --- Termux:Boot autostart for sshd ------------------------------------------
if [ -f /data/data/com.termux/files/home/.termux/boot/start-sshd.sh ]; then
  log_ok "Termux:Boot sshd autostart present"
else
  log_warn "Termux:Boot sshd autostart NOT installed (optional; for headless SSH access)"
fi

# --- sshd status -------------------------------------------------------------
if pgrep -x sshd >/dev/null 2>&1; then
  log_ok "sshd: running (port 8022)"
else
  log_info "sshd: not running (optional)"
fi
