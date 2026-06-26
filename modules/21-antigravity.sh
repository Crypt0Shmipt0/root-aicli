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

require_working_curl || exit 1

log_info "Running wallentx Termux installer (Bionic bridge + TCMalloc 39-bit fix)..."
termux_run "
  set -eu
  curl -fsSL https://raw.githubusercontent.com/wallentx/antigravity-cli-termux/dev/install.sh | bash
"

# Re-apply MLS contexts to anything new under ~/.local
apply_termux_mls "$TERMUX_HOME/.local"

if termux_run "test -x \$HOME/.local/bin/agy" 2>/dev/null; then
  log_ok "agy installed at ~/.local/bin/agy"
  termux_run "PATH=\$HOME/.local/bin:\$PATH agy --version 2>&1 | head -1" || true
else
  log_warn "agy binary missing at ~/.local/bin/agy after install."
fi

echo
log_info "Auth: open a Termux shell and run 'agy login'."
log_info "      Antigravity uses Google Sign-In via browser. No headless API key."
