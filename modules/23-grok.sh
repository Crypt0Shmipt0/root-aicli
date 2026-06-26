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
  # The grok installer succeeds in writing the binary but exits non-zero
  # because it tries to launch grok at the end (which needs a TTY we don't
  # have under su/proot). Tolerate that — we verify the binary exists below.
  alpine_run "
    apk add --no-cache curl bash >/dev/null 2>&1 || true
    curl -fsSL https://x.ai/cli/install.sh | bash
  " || log_warn "Alpine grok installer exited non-zero (TTY check). Verifying binary..."

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
  " || log_warn "Bare Termux grok install exited non-zero. Verifying binary..."
fi

apply_termux_mls "$TERMUX_HOME/.grok"
apply_termux_mls "$TERMUX_HOME/.local"
apply_termux_mls "$TERMUX_PREFIX/bin"

# Where is grok actually? Depends on Alpine vs bare. Check both.
if [ "$PREF" = "alpine" ] && [ -x "$ALPINE_ROOTFS/root/.grok/bin/grok" ]; then
  log_ok "grok installed in Alpine at /root/.grok/bin/grok (dispatcher at \$PREFIX/bin/grok)"
elif termux_run "test -x \$HOME/.grok/bin/grok" 2>/dev/null; then
  log_ok "grok installed at ~/.grok/bin/grok"
  termux_run "PATH=\$HOME/.grok/bin:\$HOME/.local/bin:\$PATH grok --version 2>&1 | head -1" || true
else
  log_warn "grok binary missing after install. Check ~/.grok/bin/grok (bare Termux) or Alpine /root/.grok/bin/grok."
  exit 1
fi

echo
log_info "Auth: open a Termux shell and either run 'grok' (browser OAuth)"
log_info "      OR set XAI_API_KEY (from https://console.x.ai) in your shell."
