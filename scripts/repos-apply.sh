#!/usr/bin/env bash
# Declaratively clone/update the repos listed in ./repos.json onto the box.
# Idempotent: re-running just fetches + checks out the declared branch.
set -euo pipefail

handle="$1"
manifest="${2:-repos.json}"

if [[ ! -f "$manifest" ]]; then
  echo "no manifest at $manifest — copy repos.example.json to repos.json" >&2
  exit 1
fi
if ! command -v jq >/dev/null; then
  echo "jq required" >&2; exit 1
fi

root="$(jq -r '.root // "~/work"' "$manifest")"
count="$(jq '.repos | length' "$manifest")"
if [[ "$count" -eq 0 ]]; then
  echo "no repos declared in $manifest"; exit 0
fi

echo "==> syncing $count repo(s) to $handle under $root"

# Build the remote script as a single stream. We emit one line per repo that
# encodes `repo|dest|branch|depth` and let the remote side loop. This avoids
# opening $count ssh connections.
plan="$(
  jq -r --arg root "$root" '
    .repos[] |
    [ .repo,
      (.dest // ($root + "/" + (.repo|split("/")|.[-1]))),
      (.branch // ""),
      (.depth // "" | tostring)
    ] | @tsv
  ' "$manifest"
)"

# Pipe the plan over stdin so the remote script can iterate without re-escaping.
printf '%s\n' "$plan" | computer ssh "$handle" -- '
  set -e
  if ! command -v gh >/dev/null 2>&1 && ! command -v git >/dev/null 2>&1; then
    echo "git/gh not installed on box; run just switch first" >&2; exit 1
  fi

  while IFS=$'"'"'\t'"'"' read -r repo dest branch depth; do
    [ -z "$repo" ] && continue
    # expand ~ in dest
    dest="${dest/#\~/$HOME}"
    mkdir -p "$(dirname "$dest")"
    if [ -d "$dest/.git" ]; then
      echo "  updating $repo → $dest"
      git -C "$dest" fetch --quiet --all --prune
      if [ -n "$branch" ]; then
        git -C "$dest" checkout --quiet "$branch" 2>/dev/null || git -C "$dest" checkout --quiet -B "$branch" "origin/$branch"
        git -C "$dest" reset --quiet --hard "origin/$branch"
      fi
    else
      echo "  cloning $repo → $dest"
      set -- --quiet
      [ -n "$branch" ] && set -- "$@" --branch "$branch"
      [ -n "$depth"  ] && set -- "$@" --depth "$depth"
      git clone "$@" "https://github.com/$repo.git" "$dest"
    fi
  done
'
echo "==> repos synced"
