#!/usr/bin/env bash
# First-run picker for repos.json. Lists the user's GitHub repos (via gh) and
# lets them pick which ones to pre-clone on every box. Writes repos.json.
set -euo pipefail

out="${1:-repos.json}"

for t in gum jq gh; do
  command -v "$t" >/dev/null || { echo "$t required" >&2; exit 1; }
done
gh auth status >/dev/null 2>&1 || { echo "gh not authenticated. run gh auth login" >&2; exit 1; }

# Default the clone root to whatever was used last time, else ~/work.
prev_root="~/work"
if [[ -f "$out" ]]; then
  prev_root="$(jq -r '.root // "~/work"' "$out" 2>/dev/null || echo '~/work')"
fi
root="$(gum input --placeholder "$prev_root" --value "$prev_root" --prompt 'clone root on box: ')"
root="${root:-$prev_root}"

echo "==> listing your repos via gh (up to 200)..."
# Collect: name_with_owner, default branch, pushed at (ISO).
repos_tsv="$(gh repo list --limit 200 --json nameWithOwner,defaultBranchRef,pushedAt \
  -q '.[] | [.nameWithOwner, (.defaultBranchRef.name // "main"), .pushedAt] | @tsv')"

if [[ -z "$repos_tsv" ]]; then
  echo "no repos found" >&2; exit 1
fi

# Sort by pushedAt desc so recently-used repos float to the top.
labels="$(printf '%s\n' "$repos_tsv" | sort -t$'\t' -k3,3r | awk -F'\t' '{print $1"  ("$2")"}')"

# Pre-select anything that was in the previous repos.json so deploys stay
# sticky unless you uncheck. Match on "owner/name" prefix of the label.
preselected=""
if [[ -f "$out" ]]; then
  prev="$(jq -r '.repos[]?.repo' "$out" 2>/dev/null || true)"
  if [[ -n "$prev" ]]; then
    while IFS= read -r line; do
      repo="${line%%  *}"
      if grep -Fxq "$repo" <<<"$prev"; then
        preselected="${preselected:+$preselected,}$line"
      fi
    done <<<"$labels"
  fi
fi

selected="$(
  printf '%s\n' "$labels" \
    | gum filter --no-limit \
        --placeholder "type to search · tab toggles · enter confirms" \
        --height 20 \
        --indicator "›" \
        --selected-prefix " ✓ " \
        --unselected-prefix "   " \
        ${preselected:+--selected "$preselected"} \
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
