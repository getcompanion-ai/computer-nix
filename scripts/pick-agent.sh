#!/usr/bin/env bash
set -euo pipefail

handle="$1"

choice="$(printf 'claude\ncodex\nboth\n' | fzf --prompt="agent creds> ")"

case "$choice" in
  claude) computer claude-login --computer "$handle" ;;
  codex)  computer codex-login  --computer "$handle" ;;
  both)
    computer claude-login --computer "$handle"
    computer codex-login  --computer "$handle"
    ;;
  *) echo "nothing selected"; exit 0 ;;
esac
