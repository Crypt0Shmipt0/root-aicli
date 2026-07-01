# shellcheck shell=bash
# Root.AICLI shared helpers. Sourced by every module. Do not exec.

# Colors (auto-disable on dumb terms or NO_COLOR)
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ] && [ "${TERM:-}" != "dumb" ]; then
  C_RED=$'\033[31m'; C_GRN=$'\033[32m'; C_YLW=$'\033[33m'
  C_BLU=$'\033[34m'; C_DIM=$'\033[2m';  C_BLD=$'\033[1m'; C_RST=$'\033[0m'
else
  C_RED=; C_GRN=; C_YLW=; C_BLU=; C_DIM=; C_BLD=; C_RST=
fi

log_info() { printf '%s[*]%s %s\n' "$C_BLU" "$C_RST" "$*"; }
log_ok()   { printf '%s[+]%s %s\n' "$C_GRN" "$C_RST" "$*"; }
log_warn() { printf '%s[!]%s %s\n' "$C_YLW" "$C_RST" "$*" >&2; }
log_err()  { printf '%s[x]%s %s\n' "$C_RED" "$C_RST" "$*" >&2; }
die()      { log_err "$*"; exit 1; }

banner() { printf '\n%s== %s ==%s\n\n' "$C_BLD" "$*" "$C_RST"; }
has_cmd() { command -v "$1" >/dev/null 2>&1; }

# --- Termux UID / MLS category detection -------------------------------------
#
# Android assigns each app a UID = 10000 + appid. The app's SELinux context is
# u:r:untrusted_app_NN:s0:c<low>,c<high+256>,c512,c768 where
#   low  = appid % 256
#   high = appid / 256
# Files written by the app land with the matching app_data_file context.
# We need this to re-apply MLS after operations that write under su (which
# defaults to magisk:s0 with no categories).
#
# Returns: u:object_r:app_data_file:s0:c<low>,c<256+high>,c512,c768
# Exits non-zero if Termux not installed.
detect_termux_mls_context() {
  local termux_uid appid low high
  termux_uid=$(stat -c %u /data/data/com.termux/files/usr 2>/dev/null) || return 1
  [ -n "$termux_uid" ] || return 1
  appid=$((termux_uid - 10000))
  low=$((appid % 256))
  high=$((appid / 256))
  printf 'u:object_r:app_data_file:s0:c%d,c%d,c512,c768' "$low" $((256 + high))
}

# Returns the Termux UID (numeric, e.g. 10211) or "" if Termux missing
detect_termux_uid() {
  stat -c %u /data/data/com.termux/files/usr 2>/dev/null
}

# Returns the Termux user (e.g. u0_a211) or "" if Termux missing
detect_termux_user() {
  stat -c %U /data/data/com.termux/files/usr 2>/dev/null
}

# Root manager: magisk | kernelsu | apatch | unknown
detect_root_manager() {
  if [ -d /data/adb/magisk ] || [ -d /data/adb/modules ]; then echo magisk; return
  elif [ -d /data/adb/ksu ] || [ -d /data/adb/ksud ]; then echo kernelsu; return
  elif [ -d /data/adb/ap ]; then echo apatch; return
  fi
  echo unknown
}

# Where to drop a boot-time persistence script for the detected root manager.
detect_service_dir() {
  case "$(detect_root_manager)" in
    magisk)   echo /data/adb/service.d ;;
    kernelsu) echo /data/adb/post-fs-data.d ;;
    apatch)   echo /data/adb/post-fs-data.d ;;
    *)        echo "" ;;
  esac
}

# Detect whether Termux is running on bare Bionic or whether an Alpine
# proot-distro container is available. Output: "alpine" if Alpine present and
# usable, otherwise "bionic".
#
# Note: we check for /etc/alpine-release (a plain file) rather than bin/sh
# (a symlink to /bin/busybox that only resolves correctly inside the proot).
# From outside the proot the symlink's target path doesn't exist, so -x
# returns false even when Alpine is fully installed.
detect_runtime_preference() {
  local termux_files=/data/data/com.termux/files
  local alpine_root=$termux_files/usr/var/lib/proot-distro/containers/alpine/rootfs
  if [ -f "$alpine_root/etc/alpine-release" ]; then
    echo alpine
  else
    echo bionic
  fi
}

# Magisk root sanity check
require_root() {
  if ! su -c 'id' 2>/dev/null | grep -q 'uid=0'; then
    die "Root not available. Install Magisk, KernelSU, or APatch first."
  fi
}

# Run a command inside Termux (bare Bionic context) with full Termux env.
# Used from outside Termux when we already have root (via the APK).
#
# We synthesize TERMUX_VERSION because installers like wallentx's agy gate on
# its presence to detect "is this a real Termux session." The actual value
# does not matter, only that it is non-empty. We probe Termux's package
# manager for the real version and fall back to a default.
termux_run() {
  local termux_files=/data/data/com.termux/files
  local cmd="$*"
  local termux_version
  termux_version=$(cat "$termux_files/usr/etc/termux-version" 2>/dev/null || echo "0.118.3")
  HOME=$termux_files/home \
  PREFIX=$termux_files/usr \
  TMPDIR=$termux_files/usr/tmp \
  PATH=$termux_files/usr/bin:$PATH \
  LD_LIBRARY_PATH=$termux_files/usr/lib \
  TERMUX_VERSION=$termux_version \
  "$termux_files/usr/bin/bash" -c "$cmd"
}

# Same, but inside Alpine proot-distro container.
alpine_run() {
  local termux_files=/data/data/com.termux/files
  local cmd="$*"
  HOME=$termux_files/home \
  PREFIX=$termux_files/usr \
  TMPDIR=$termux_files/usr/tmp \
  PATH=$termux_files/usr/bin:$PATH \
  LD_LIBRARY_PATH=$termux_files/usr/lib \
  "$termux_files/usr/bin/proot-distro" login alpine --shared-tmp -- sh -c "$cmd"
}

# Apply the Termux MLS context (recursively) to a path. Needed after any write
# done under su, otherwise Termux can't read/exec what we put there.
apply_termux_mls() {
  local target=$1
  # Early exit if the path doesn't exist. `find` on a missing path returns 1,
  # and `pipefail` propagates that out of the pipe and trips `set -e` even
  # with a trailing `return 0`. Cleaner to skip the pipeline entirely.
  [ -e "$target" ] || return 0
  local ctx
  ctx=$(detect_termux_mls_context 2>/dev/null) || return 0
  local termux_user
  termux_user=$(detect_termux_user 2>/dev/null)
  [ -n "$termux_user" ] || return 0
  # `|| true` on each chown/chcon so a single failing file doesn't abort the
  # parent module under `set -e`. Some files (broken symlinks, FUSE mounts)
  # legitimately refuse chcon; we want best-effort relabeling, not all or
  # nothing.
  find "$target" 2>/dev/null | while read -r f; do
    chown -h "$termux_user:$termux_user" "$f" 2>/dev/null || true
    chcon -h "$ctx" "$f" 2>/dev/null || true
  done || true
  return 0
}

# Confirm prompt (TOMER_TWEAKS_YES=1 / ROOT_AICLI_YES=1 auto-confirms)
confirm() {
  local prompt="${1:-Continue?} [y/N] "
  if [ "${ROOT_AICLI_YES:-0}" = "1" ]; then return 0; fi
  printf '%s' "$prompt"
  local ans; read -r ans
  case "$ans" in y|Y|yes|YES) return 0 ;; *) return 1 ;; esac
}

# Verify Termux's curl actually works (not just present-on-disk). Stale
# package states are common after long gaps: libcurl's QUIC dependency
# `libngtcp2_crypto_ossl.so` references symbols only present in newer
# openssl, and curl refuses to link until both are updated together.
#
# Surfaces a clear instruction if broken. Returns non-zero so the calling
# module can exit early.
require_working_curl() {
  if termux_run "curl --version >/dev/null 2>&1" 2>/dev/null; then
    return 0
  fi
  log_err "Termux's curl is not working (broken package linkage)."
  log_err ""
  log_err "This usually means libcurl, libngtcp2, and openssl are out of sync."
  log_err "Open Termux on the device and run:"
  log_err ""
  log_err "  pkg upgrade -y"
  log_err ""
  log_err "or, if pkg upgrade itself errors:"
  log_err ""
  log_err "  pkg install -y --reinstall libcurl libngtcp2 openssl ca-certificates curl"
  log_err ""
  log_err "Then come back and re-run this action."
  return 1
}

# Constants
export TERMUX_HOME="${HOME:-/data/data/com.termux/files/home}"
export TERMUX_PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"
export ALPINE_ROOTFS="$TERMUX_PREFIX/var/lib/proot-distro/containers/alpine/rootfs"

# --- Claude dispatcher (Alpine mode) -----------------------------------------
#
# In Alpine mode the real Claude binary lives inside the proot-distro Alpine
# container; a thin Termux dispatcher forwards `claude ...` into it. The catch:
# a native `claude` self-update (or a bare-Termux install) drops a
# ~/.local/bin/claude that sits AHEAD of $PREFIX/bin in PATH and silently
# shadows the dispatcher, so `claude` breaks while every other CLI still works.
# We defend by writing the dispatcher to every entry point a native install can
# occupy, keeping a canonical copy, and reasserting via a login-shell guard
# (this file) + the boot hook (modules/50-persistence.sh).

# Path to the canonical dispatcher copy the boot hook restores from.
export CLAUDE_DISPATCHER_CANON="$TERMUX_PREFIX/libexec/root-aicli/claude-dispatcher"

# Emit the dispatcher script body on stdout (single source of truth).
claude_dispatcher_body() {
  cat <<'EOF'
#!/data/data/com.termux/files/usr/bin/env bash
# Dispatcher installed by Root.AICLI: forwards `claude ...` into the Alpine
# proot-distro container where the actual Claude binary lives.
exec proot-distro login alpine --shared-tmp -- claude "$@"
EOF
}

# Install the dispatcher to all three PATH entry points a native `claude`
# install can occupy (~/.local/bin, ~/bin, $PREFIX/bin), removing any native
# shadow, keep a canonical copy, and re-apply Termux MLS. Alpine mode only.
install_claude_dispatcher() {
  local p
  mkdir -p "$(dirname "$CLAUDE_DISPATCHER_CANON")"
  claude_dispatcher_body > "$CLAUDE_DISPATCHER_CANON"
  chmod 755 "$CLAUDE_DISPATCHER_CANON"
  for p in "$TERMUX_HOME/.local/bin/claude" "$TERMUX_HOME/bin/claude" "$TERMUX_PREFIX/bin/claude"; do
    mkdir -p "$(dirname "$p")"
    rm -f "$p"
    cp "$CLAUDE_DISPATCHER_CANON" "$p"
    chmod 755 "$p"
    apply_termux_mls "$p"
  done
  apply_termux_mls "$CLAUDE_DISPATCHER_CANON"
}

# Drop a login-shell guard (sourced from $PREFIX/etc/profile.d) that reasserts
# the dispatcher if a `claude` self-update recreated a native ~/.local/bin/claude
# shadow since the last boot. Runs as the Termux user, so the rewritten file
# inherits the correct SELinux context with no chcon needed. Zero-gap: heals on
# the next terminal open, not just on reboot.
install_claude_session_guard() {
  local guard="$TERMUX_PREFIX/etc/profile.d/root-aicli-claude.sh"
  mkdir -p "$TERMUX_PREFIX/etc/profile.d"
  cat > "$guard" <<'EOF'
# Root.AICLI: keep `claude` routed through the Alpine dispatcher. A native
# `claude` self-update recreates ~/.local/bin/claude and shadows the dispatcher
# in PATH; reassert it on each login shell.
_rc="$HOME/.local/bin/claude"
if [ -e "$_rc" ] && ! grep -q 'proot-distro login alpine' "$_rc" 2>/dev/null; then
  rm -f "$_rc"
  printf '#!/data/data/com.termux/files/usr/bin/env bash\nexec proot-distro login alpine --shared-tmp -- claude "$@"\n' > "$_rc"
  chmod 755 "$_rc"
fi
unset _rc
EOF
  chmod 644 "$guard"
  apply_termux_mls "$guard"
}
