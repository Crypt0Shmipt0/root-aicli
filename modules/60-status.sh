#!/data/data/com.termux/files/usr/bin/env bash
# Wrapper: status is just 00-detect with a different banner.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
exec bash "$HERE/00-detect.sh"
