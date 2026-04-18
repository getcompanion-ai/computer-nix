#!/usr/bin/env bash
set -euo pipefail

handle="$1"

if ! command -v bw >/dev/null; then
  echo "bw cli required" >&2
  exit 1
fi

status="$(bw status | jq -r '.status')"
case "$status" in
  unauthenticated) echo "run: bw login" >&2; exit 1 ;;
  locked)          export BW_SESSION="$(bw unlock --raw)" ;;
  unlocked)        : ;;
esac

selection="$(
  bw list items \
    | jq -r '.[] | "\(.id)\t\(.name)\t\(.login.username // "-")"' \
    | fzf -m --prompt="secrets> " --with-nth=2,3 --delimiter=$'\t' \
    | cut -f1
)"

if [[ -z "$selection" ]]; then
  echo "no items selected" >&2
  exit 0
fi

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

env_file="$tmp/shell.zsh"
: > "$env_file"

while IFS= read -r id; do
  [[ -z "$id" ]] && continue
  item="$(bw get item "$id")"
  name="$(jq -r '.name' <<< "$item")"
  safe_name="$(echo "$name" | tr '[:lower:] -' '[:upper:]__' | tr -cd 'A-Z0-9_')"

  password="$(jq -r '.login.password // empty' <<< "$item")"
  if [[ -n "$password" ]]; then
    printf 'export %s=%q\n' "$safe_name" "$password" >> "$env_file"
  fi

  while IFS= read -r field; do
    [[ -z "$field" ]] && continue
    fname="$(jq -r '.name' <<< "$field" | tr '[:lower:] -' '[:upper:]__' | tr -cd 'A-Z0-9_')"
    fval="$(jq -r '.value // empty' <<< "$field")"
    [[ -z "$fval" || -z "$fname" ]] && continue
    printf 'export %s=%q\n' "$fname" "$fval" >> "$env_file"
  done < <(jq -c '.fields[]?' <<< "$item")
done <<< "$selection"

echo "==> pushing $(wc -l < "$env_file") env lines to $handle:~/.config/secrets/shell.zsh"
computer ssh "$handle" -- "mkdir -p ~/.config/secrets && chmod 700 ~/.config/secrets"
computer sync "$env_file" --computer "$handle" >/dev/null

computer ssh "$handle" -- "
  set -e
  mkdir -p ~/.config/secrets
  mv ~/shell.zsh ~/.config/secrets/shell.zsh
  chmod 600 ~/.config/secrets/shell.zsh
"

echo "==> done. new shells on $handle will source ~/.config/secrets/shell.zsh"
