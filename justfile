set dotenv-load := true

default:
  @just --list

# One-shot onboarding: pick box once, idempotent. Repos always prompts. Pass 'force' to redo.
go handle='' mode='':
  #!/usr/bin/env bash
  set -euo pipefail
  h="$(./scripts/pick-handle.sh '{{ handle }}')"
  force=""
  if [[ '{{ mode }}' == "force" ]]; then force=1; fi
  marker_dir='~/.cache/computer-nix'
  done_on_box() { computer ssh "$h" -- "test -f ${marker_dir}/$1.done" >/dev/null 2>&1; }
  mark_done()   { computer ssh "$h" -- "mkdir -p ${marker_dir} && touch ${marker_dir}/$1.done" >/dev/null; }
  step()        { ./scripts/run-step.sh "$@"; }
  skip()        { printf '  \033[90m·\033[0m [%s] %s · skipped\n' "$1" "$2"; }

  echo "==> onboarding $h"
  if [[ -n "$force" ]]; then
    echo "    force: wiping markers on $h"
    computer ssh "$h" -- "rm -rf ${marker_dir}" >/dev/null 2>&1 || true
  fi

  step "1/5" "switch (home-manager)" ./scripts/bootstrap.sh "$h"

  if done_on_box auth; then
    skip "2/5" "gh auth"
  else
    step "2/5" "gh auth" ./scripts/auth-apply.sh "$h"
    mark_done auth
  fi

  if done_on_box secrets; then
    skip "3/5" "secrets"
  else
    if [[ ! -f secrets.json ]]; then
      echo "    no secrets.json yet — launching picker"
      ./scripts/secrets-init.sh
    fi
    step "3/5" "secrets" ./scripts/secrets-apply.sh "$h"
    mark_done secrets
  fi

  if done_on_box agent; then
    skip "4/5" "agent creds (claude + codex)"
  else
    step "4/5" "claude login" computer claude-login "$h"
    step "4/5" "codex login"  computer codex-login  "$h"
    mark_done agent
  fi

  echo "    picking repos..."
  ./scripts/repos-init.sh
  step "5/5" "clone repos" ./scripts/repos-apply.sh "$h"

  echo
  echo "==> done. connecting to $h..."
  exec computer ssh "$h"

# Apply the flake to a computer
switch handle='':
  #!/usr/bin/env bash
  set -euo pipefail
  h="$(./scripts/pick-handle.sh '{{ handle }}')"
  ./scripts/bootstrap.sh "$h"

# Push laptop-side gh auth onto the box (for private repos)
auth handle='':
  #!/usr/bin/env bash
  set -euo pipefail
  h="$(./scripts/pick-handle.sh '{{ handle }}')"
  ./scripts/auth-apply.sh "$h"

# Declaratively apply ./secrets.json
secrets handle='':
  #!/usr/bin/env bash
  set -euo pipefail
  h="$(./scripts/pick-handle.sh '{{ handle }}')"
  ./scripts/secrets-apply.sh "$h"

# Interactive picker: generates secrets.json (run once, then commit)
secrets-init:
  ./scripts/secrets-init.sh

# Declaratively apply ./repos.json
repos handle='':
  #!/usr/bin/env bash
  set -euo pipefail
  h="$(./scripts/pick-handle.sh '{{ handle }}')"
  ./scripts/repos-apply.sh "$h"

# Interactive picker: generates repos.json (run once, then commit)
repos-init:
  ./scripts/repos-init.sh

# Copy agent credentials (claude + codex) onto a computer
agent handle='':
  #!/usr/bin/env bash
  set -euo pipefail
  h="$(./scripts/pick-handle.sh '{{ handle }}')"
  ./scripts/pick-agent.sh "$h"

# Create a new computer using COMPUTER_SIZE + COMPUTER_DISK_GIB from .env
create handle:
  computer create --size ${COMPUTER_SIZE} --storage ${COMPUTER_DISK_GIB:-30} {{ handle }}
