#!/data/data/com.termux/files/usr/bin/env bash
# Install or repair OpenAI's Codex CLI (the Rust agentic terminal client,
# not the deprecated 2021 completions API).
#
# Repo: https://github.com/openai/codex (Apache-2.0)
# Binary: linux-arm64-musl, native-Termux compatible.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/../lib/common.sh"

banner "Install / repair OpenAI Codex CLI"

require_root

require_working_curl || exit 1

log_info "Running official Codex installer (chatgpt.com/codex/install.sh)..."
termux_run "
  set -eu
  # The installer drops the codex binary in ~/.local/bin and adds it to PATH.
  curl -fsSL https://chatgpt.com/codex/install.sh | sh
"

# Re-apply MLS so codex binary is reachable from a real Termux session.
apply_termux_mls "$TERMUX_HOME/.local"
apply_termux_mls "$TERMUX_HOME/.codex"

if termux_run "command -v codex" >/dev/null 2>&1; then
  log_ok "codex installed:"
  termux_run "codex --version 2>&1 | head -1" || true
else
  log_warn "codex binary not on PATH after install. Check ~/.local/bin/codex."
fi

echo
log_info "Auth: open a Termux shell and run 'codex'. First run will prompt for"
log_info "      ChatGPT OAuth (browser) OR set OPENAI_API_KEY in your shell."
