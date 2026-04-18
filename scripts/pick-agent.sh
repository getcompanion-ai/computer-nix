#!/usr/bin/env bash
set -euo pipefail

handle="$1"

choice="$(printf 'claude\ncodex\nboth\n' | fzf --prompt="agent creds> ")"

case "$choice" in
  claude) computer claude-login "$handle" ;;
  codex)  computer codex-login  "$handle" ;;
  both)
    computer claude-login "$handle"
    computer codex-login  "$handle"
    ;;
  *) echo "nothing selected"; exit 0 ;;
esac
