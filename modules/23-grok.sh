#!/data/data/com.termux/files/usr/bin/env bash
# Install or repair xAI's Grok Build CLI.
#
# Repo / install endpoint: https://x.ai/cli/install.sh
# Status (mid-2026): NEW (launched May 2026). Bionic compatibility unverified;
# this module installs the official build and reports back. If it fails on
# bare Termux Bionic, the user should install Alpine via 'pkg install proot-distro'
# then re-run this module — Root.AICLI will auto-prefer Alpine when present.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/../lib/common.sh"

banner "Install / repair xAI Grok Build CLI"

require_root

require_working_curl || exit 1

PREF=$(detect_runtime_preference)

if [ "$PREF" = "alpine" ]; then
  log_info "Alpine present; installing grok inside Alpine (glibc/musl)."
  alpine_run "
    set -eu
    apk add --no-cache curl bash >/dev/null
    curl -fsSL https://x.ai/cli/install.sh | bash
  "
  # Symlink grok inside Termux so 'grok' works without entering Alpine
  DISP=$TERMUX_PREFIX/bin/grok
  if [ ! -e "$DISP" ]; then
    cat > "$DISP" <<'EOF'
#!/data/data/com.termux/files/usr/bin/env bash
# Dispatcher installed by Root.AICLI: forwards `grok ...` into Alpine.
exec proot-distro login alpine --shared-tmp -- grok "$@"
EOF
    chmod 755 "$DISP"
  fi
else
  log_info "Bare Termux Bionic; attempting native install. May fail if binary is glibc-only."
  termux_run "
    set -eu
    curl -fsSL https://x.ai/cli/install.sh | bash
  " || {
    log_err "Native install failed on bare Termux Bionic."
    log_err "Recommendation: install Alpine first:"
    log_err "  pkg install proot-distro && proot-distro install alpine"
    log_err "Then re-run Root.AICLI -> Install Grok."
    exit 1
  }
fi

apply_termux_mls "$TERMUX_HOME/.grok"
apply_termux_mls "$TERMUX_HOME/.local"
apply_termux_mls "$TERMUX_PREFIX/bin"  # in case the Alpine dispatcher was just written

# Grok installer places binary at ~/.grok/bin/grok
if termux_run "test -x \$HOME/.grok/bin/grok" 2>/dev/null; then
  log_ok "grok installed at ~/.grok/bin/grok"
  termux_run "PATH=\$HOME/.grok/bin:\$HOME/.local/bin:\$PATH grok --version 2>&1 | head -1" || true
else
  log_warn "grok binary missing at ~/.grok/bin/grok after install."
fi

echo
log_info "Auth: open a Termux shell and either run 'grok' (browser OAuth)"
log_info "      OR set XAI_API_KEY (from https://console.x.ai) in your shell."
