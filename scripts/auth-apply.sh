#!/usr/bin/env bash
# Push laptop-side `gh` auth to the box so that subsequent `gh repo clone` and
# `git push` work for private repos without interactive prompts.
#
# Uses the laptop's existing gh auth (typically stored in the macOS keychain).
# The token is piped to the box over stdin and never written to disk on the
# laptop.
set -euo pipefail

handle="$1"

if ! command -v gh >/dev/null; then
  echo "gh CLI required" >&2; exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
  echo "gh not authenticated on laptop. run: gh auth login" >&2; exit 1
fi

# Fetch the token locally (never echoed).
token="$(gh auth token 2>/dev/null)"
if [[ -z "$token" ]]; then
  echo "could not read gh token" >&2; exit 1
fi

echo "==> installing gh auth on $handle"
# Push the token via stdin to `gh auth login --with-token` on the box.
# Also set up git credential.helper so git itself can push without prompts.
printf '%s\n' "$token" | computer ssh "$handle" -- '
  set -e
  if ! command -v gh >/dev/null 2>&1; then
    echo "gh not installed on box; skipping"
    exit 0
  fi
  gh auth login --hostname github.com --with-token >/dev/null
  gh auth setup-git >/dev/null 2>&1 || true
' >/dev/null

# Zero the local copy and drop the variable.
token=""
unset token

echo "==> done. verify with: computer ssh $handle -- gh auth status"
