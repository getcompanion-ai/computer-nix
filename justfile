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
  if [[ -n "$force" ]]; then
    echo "==> force: wiping markers on $h"
    computer ssh "$h" -- "rm -rf ${marker_dir}" >/dev/null || true
  fi

  echo "==> [1/5] switch (home-manager apply)"
  ./scripts/bootstrap.sh "$h"

  echo "==> [2/5] gh auth"
  if done_on_box auth; then echo "     already done — skipping (pass 'force' to redo)"
  else ./scripts/auth-apply.sh "$h" && mark_done auth; fi

  echo "==> [3/5] secrets"
  if done_on_box secrets; then echo "     already done — skipping (pass 'force' to redo)"
  else
    if [[ ! -f secrets.json ]]; then
      echo "     no secrets.json yet — launching picker"
      ./scripts/secrets-init.sh
    fi
    ./scripts/secrets-apply.sh "$h" && mark_done secrets
  fi

  echo "==> [4/5] agent creds (claude + codex)"
  if done_on_box agent; then echo "     already done — skipping (pass 'force' to redo)"
  else
    computer claude-login "$h" || true
    computer codex-login  "$h" || true
    mark_done agent
  fi

  echo "==> [5/5] repos (pick for this box)"
  ./scripts/repos-init.sh
  ./scripts/repos-apply.sh "$h"

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

# Create a new computer using COMPUTER_SIZE from .env
create handle:
  computer create --size ${COMPUTER_SIZE} {{ handle }}
