set dotenv-load := true

default:
  @just --list

# One-shot: bootstrap + gh auth + secrets + repos + agent creds
go handle='':
  #!/usr/bin/env bash
  set -euo pipefail
  h="$(./scripts/pick-handle.sh '{{ handle }}')"
  echo "==> [1/5] switch"
  ./scripts/bootstrap.sh "$h"
  echo "==> [2/5] gh auth"
  ./scripts/auth-apply.sh "$h"
  echo "==> [3/5] secrets"
  if [[ -f secrets.json ]]; then ./scripts/secrets-apply.sh "$h"
  else echo "     (no secrets.json — skipping; run: just secrets-init)"; fi
  echo "==> [4/5] repos"
  if [[ -f repos.json ]]; then ./scripts/repos-apply.sh "$h"
  else echo "     (no repos.json — skipping; run: just repos-init)"; fi
  echo "==> [5/5] agent creds (claude + codex)"
  computer claude-login "$h" || true
  computer codex-login  "$h" || true
  echo
  echo "==> done. ssh in with: computer ssh $h"

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
