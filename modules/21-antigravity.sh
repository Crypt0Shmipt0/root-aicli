#!/data/data/com.termux/files/usr/bin/env bash
# Install or repair Google's Antigravity CLI (agy) for Termux.
#
# The official Google installer is proprietary and glibc-linked. Wallentx
# maintains a Termux-native fork that bundles a Bionic-glibc bridge and the
# TCMalloc 39-bit-VA fix needed for proot scenarios. We use the fork.
#
# Repo: https://github.com/wallentx/antigravity-cli-termux
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/../lib/common.sh"

banner "Install / repair Antigravity (agy)"

require_root

if ! termux_run "command -v curl" >/dev/null 2>&1; then
  log_info "Installing curl in Termux..."
  termux_run "pkg install -y curl"
fi

log_info "Running wallentx Termux installer (Bionic bridge + TCMalloc 39-bit fix)..."
termux_run "
  set -eu
  curl -fsSL https://raw.githubusercontent.com/wallentx/antigravity-cli-termux/dev/install.sh | bash
"

# Re-apply MLS contexts to anything new under ~/.local
apply_termux_mls "$TERMUX_HOME/.local"

if termux_run "command -v agy" >/dev/null 2>&1; then
  log_ok "agy installed:"
  termux_run "agy --version" | head -1 || true
else
  log_warn "agy binary not on PATH after install. Check ~/.local/bin/agy."
fi

echo
log_info "Auth: open a Termux shell and run 'agy login'."
log_info "      Antigravity uses Google Sign-In via browser. No headless API key."
