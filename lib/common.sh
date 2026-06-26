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
detect_runtime_preference() {
  local termux_files=/data/data/com.termux/files
  local alpine_root=$termux_files/usr/var/lib/proot-distro/containers/alpine/rootfs
  if [ -d "$alpine_root" ] && [ -x "$alpine_root/bin/sh" ]; then
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
termux_run() {
  local termux_files=/data/data/com.termux/files
  local cmd="$*"
  HOME=$termux_files/home \
  PREFIX=$termux_files/usr \
  TMPDIR=$termux_files/usr/tmp \
  PATH=$termux_files/usr/bin:$PATH \
  LD_LIBRARY_PATH=$termux_files/usr/lib \
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
  local ctx
  ctx=$(detect_termux_mls_context 2>/dev/null) || return 0
  local termux_user
  termux_user=$(detect_termux_user 2>/dev/null)
  [ -n "$termux_user" ] || return 0
  find "$target" 2>/dev/null | while read -r f; do
    chown -h "$termux_user:$termux_user" "$f" 2>/dev/null
    chcon -h "$ctx" "$f" 2>/dev/null
  done
}

# Confirm prompt (TOMER_TWEAKS_YES=1 / ROOT_AICLI_YES=1 auto-confirms)
confirm() {
  local prompt="${1:-Continue?} [y/N] "
  if [ "${ROOT_AICLI_YES:-0}" = "1" ]; then return 0; fi
  printf '%s' "$prompt"
  local ans; read -r ans
  case "$ans" in y|Y|yes|YES) return 0 ;; *) return 1 ;; esac
}

# Constants
export TERMUX_HOME="${HOME:-/data/data/com.termux/files/home}"
export TERMUX_PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"
export ALPINE_ROOTFS="$TERMUX_PREFIX/var/lib/proot-distro/containers/alpine/rootfs"
