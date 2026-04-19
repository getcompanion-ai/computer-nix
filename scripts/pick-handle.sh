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
if ! command -v jq >/dev/null; then
  echo "jq required" >&2
  exit 1
fi

# Stage the list to a temp file. If we pipe `computer ls | jq | fzf` directly,
# `set -o pipefail` + SIGPIPE from fzf closing its read end can fail the whole
# pipeline on Enter. And some `computer` CLI builds emit spinner text to stdout
# before the JSON, so we explicitly extract only the JSON object.
tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

raw="$(computer ls --json 2>/dev/null || true)"
# Strip any leading non-JSON noise: keep from the first `{` onwards.
json="${raw#"${raw%%\{*}"}"

if [[ -z "$json" ]]; then
  echo "computer ls --json returned no JSON output" >&2
  exit 1
fi

printf '%s' "$json" \
  | jq -r '.computers[]? | "\(.handle)\t\(.state // .status // "-")"' \
  > "$tmp" || true

if [[ ! -s "$tmp" ]]; then
  echo "no computers found (run: just create <handle>)" >&2
  exit 1
fi

# IMPORTANT: order of redirections matters in bash. fzf's stdin must be the
# tempfile (the choices). fzf opens /dev/tty on its own for keyboard input, so
# we do NOT redirect /dev/tty onto stdin — doing that made fzf read keystrokes
# as the choice list, which manifested as fzf showing files from the cwd.
handle="$(fzf \
  --prompt="computer> " \
  --with-nth=1,2 \
  --delimiter=$'\t' \
  --height=40% \
  --reverse \
  <"$tmp" \
  | cut -f1)" || true

if [[ -z "${handle:-}" ]]; then
  echo "no computer selected" >&2
  exit 1
fi

echo "$handle"
