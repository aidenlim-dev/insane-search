#!/usr/bin/env bash
# Run the insane-search engine through an isolated Python environment.
#
# This avoids modifying a student's system Python. It also works around macOS
# Homebrew/PEP 668 environments where global `pip install` is rejected.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENGINE_ROOT="$ROOT/skills/insane-search"
VENV_DIR="${INSANE_SEARCH_VENV:-${XDG_CACHE_HOME:-$HOME/.cache}/insane-search/venv}"
STAMP="$VENV_DIR/.insane-search-deps-v2"

if ! command -v python3 >/dev/null 2>&1; then
  echo "insane-search: python3 is required but was not found" >&2
  exit 127
fi

if [ ! -x "$VENV_DIR/bin/python" ]; then
  mkdir -p "$(dirname "$VENV_DIR")"
  python3 -m venv "$VENV_DIR"
fi

if [ ! -f "$STAMP" ]; then
  LOG="$VENV_DIR/install.log"
  if ! "$VENV_DIR/bin/python" -m pip install -U pip >"$LOG" 2>&1; then
    cat "$LOG" >&2
    exit 1
  fi
  if ! "$VENV_DIR/bin/python" -m pip install -U \
      "curl_cffi>=0.15.0" \
      beautifulsoup4 \
      pyyaml \
      yt-dlp \
      >>"$LOG" 2>&1; then
    cat "$LOG" >&2
    exit 1
  fi
  date +%s > "$STAMP"
fi

cd "$ENGINE_ROOT"
PYTHONPATH="$ENGINE_ROOT${PYTHONPATH:+:$PYTHONPATH}" exec "$VENV_DIR/bin/python" -m engine "$@"
