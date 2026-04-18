#!/usr/bin/env bash
set -euo pipefail

handle="$1"
clone_path="${CLONE_PATH:-~/Documents/github}"

if ! gh auth status >/dev/null 2>&1; then
  echo "gh not authenticated: run 'gh auth login'" >&2
  exit 1
fi

selection="$(
  gh repo list --limit 1000 --json nameWithOwner,description \
    | jq -r '.[] | "\(.nameWithOwner)\t\(.description // "")"' \
    | fzf -m --prompt="repos> " --with-nth=1,2 --delimiter=$'\t' \
    | cut -f1
)"

if [[ -z "$selection" ]]; then
  echo "no repos selected" >&2
  exit 0
fi

echo "==> cloning into $clone_path on $handle"
while IFS= read -r repo; do
  [[ -z "$repo" ]] && continue
  echo "  - $repo"
  computer ssh "$handle" -- "
    set -e
    mkdir -p ${clone_path}
    cd ${clone_path}
    if [ ! -d \"\$(basename '$repo')\" ]; then
      gh repo clone '$repo' || git clone https://github.com/$repo.git
    else
      echo '    already cloned, skipping'
    fi
  "
done <<< "$selection"
