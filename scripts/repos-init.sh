#!/usr/bin/env bash
# First-run picker for repos.json. Lists the user's GitHub repos (via gh) and
# lets them pick which ones to pre-clone on every box. Writes repos.json.
set -euo pipefail

out="${1:-repos.json}"

if [[ -f "$out" ]]; then
  echo "$out already exists. delete or pass a different path." >&2; exit 1
fi
for t in gum jq gh; do
  command -v "$t" >/dev/null || { echo "$t required" >&2; exit 1; }
done
gh auth status >/dev/null 2>&1 || { echo "gh not authenticated. run gh auth login" >&2; exit 1; }

root="$(gum input --placeholder '~/work' --prompt 'clone root on box: ')"
root="${root:-~/work}"

echo "==> listing your repos via gh (up to 200)..."
# Collect: name_with_owner, default branch, pushed at (ISO).
repos_tsv="$(gh repo list --limit 200 --json nameWithOwner,defaultBranchRef,pushedAt \
  -q '.[] | [.nameWithOwner, (.defaultBranchRef.name // "main"), .pushedAt] | @tsv')"

if [[ -z "$repos_tsv" ]]; then
  echo "no repos found" >&2; exit 1
fi

# Sort by pushedAt desc so recently-used repos float to the top.
labels="$(printf '%s\n' "$repos_tsv" | sort -t$'\t' -k3,3r | awk -F'\t' '{print $1"  ("$2")"}')"

selected="$(
  printf '%s\n' "$labels" \
    | gum choose --no-limit \
        --header "select repos to pre-clone on every box (enter confirms)" \
        --height 20 \
    || true
)"

if [[ -z "$selected" ]]; then
  echo "nothing selected, not writing $out" >&2; exit 1
fi

entries='[]'
while IFS= read -r line; do
  [[ -z "$line" ]] && continue
  # line: "owner/name  (branch)"
  repo="${line%%  *}"
  branch="${line##*(}"; branch="${branch%)*}"
  entries="$(jq -c --arg r "$repo" --arg b "$branch" '. + [{repo:$r, branch:$b}]' <<<"$entries")"
done <<<"$selected"

jq -n --arg root "$root" --argjson repos "$entries" \
  '{root:$root, repos:$repos}' >"$out"

echo
echo "==> wrote $out with $(jq '.repos|length' "$out") repo(s)."
echo "review it, commit to your fork, then run: just repos <handle>"
