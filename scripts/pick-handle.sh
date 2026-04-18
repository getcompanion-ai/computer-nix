#!/usr/bin/env bash
set -euo pipefail

given="${1:-}"
if [[ -n "$given" ]]; then
  echo "$given"
  exit 0
fi

if ! command -v fzf >/dev/null; then
  echo "fzf required" >&2
  exit 1
fi

handle="$(
  computer ls --json \
    | jq -r '.computers[] | "\(.handle)\t\(.state // .status // "-")"' \
    | fzf --prompt="computer> " --with-nth=1,2 --delimiter=$'\t' \
    | cut -f1
)"

if [[ -z "$handle" ]]; then
  echo "no computer selected" >&2
  exit 1
fi

echo "$handle"
