#!/usr/bin/env bash
set -euo pipefail

handle="$1"
flake_ref="${FLAKE_REF:-github:getcompanion-ai/computer-nix#computer}"

echo "==> target: $handle"
echo "==> flake:  $flake_ref"

remote() { computer ssh "$handle" -- "$@"; }

if ! remote 'command -v nix >/dev/null 2>&1'; then
  echo "==> installing nix (determinate installer, no confirm)"
  remote 'curl --proto "=https" --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install linux --no-confirm --init none'
fi

remote '
  set -e
  export PATH="$HOME/.nix-profile/bin:/nix/var/nix/profiles/default/bin:$PATH"
  if [ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  fi
  mkdir -p ~/.config/nix
  grep -q "experimental-features" ~/.config/nix/nix.conf 2>/dev/null \
    || echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
'

echo "==> applying home-manager flake"
remote "
  set -e
  export PATH=\"\$HOME/.nix-profile/bin:/nix/var/nix/profiles/default/bin:\$PATH\"
  nix run nixpkgs#home-manager -- switch --flake '${flake_ref}' -b backup --refresh
"

echo "==> done. connect with: computer ssh $handle --tmux"
