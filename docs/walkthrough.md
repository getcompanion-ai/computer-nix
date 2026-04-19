# Walkthrough

<img width="600" alt="terminal screenshot" src="https://github.com/user-attachments/assets/e4dfe881-6999-4dc6-b762-d164e99fdd79" />

Zero to a working box, with the "why" behind each step.

## 1. Install prereqs

```
curl -fsSL https://agentcomputer.ai/install.sh | bash
brew install just gum jq fzf gh     # or your package manager
brew install bitwarden-cli          # optional, only if you use bw for secrets
gh auth login
computer login
```

## 2. Fork the template

```
gh repo create my-computer-nix --template getcompanion-ai/computer-nix --public --clone
cd my-computer-nix
cp .env.example .env
```

Edit `.env`:

```
FLAKE_REF=github:<you>/my-computer-nix#computer
COMPUTER_SIZE=ram-4g
```

Commit and push — `FLAKE_REF` must resolve over the network:

```
git add . && git commit -m "init" && git push
```

## 3. Create a box

```
just create mybox
```

Thin wrapper for `computer create --size $COMPUTER_SIZE mybox`.

## 4. Onboard the box

```
just go mybox
```

One command runs the full flow, idempotently per-box:

1. **switch** — installs Nix (Determinate installer) if missing, starts `nix-daemon`, runs `home-manager switch --flake $FLAKE_REF`. Cheap on re-run.
2. **auth** — pipes your laptop's `gh auth token` over stdin into `gh auth login --with-token` on the box, then `gh auth setup-git` so private clones/pushes work. Skipped if already done.
3. **secrets** — if `./secrets.json` is missing, launches an interactive `gum` picker that discovers candidates from Bitwarden, your env, and well-known config files; writes `./secrets.json`. Then `secrets-apply.sh` resolves every entry and pushes `~/.config/secrets/shell.zsh` (mode 0600) to the box. Skipped if already done.
4. **agent creds** — `computer claude-login` + `computer codex-login`. Skipped if already done.
5. **repos** — always launches the `gum` fuzzy picker over `gh repo list`. Previously-picked repos are pre-selected so deploys stay sticky. Clones into the configured root on the box.

Idempotency markers live at `~/.cache/computer-nix/*.done` on the box. To redo everything:

```
just go mybox force
```

## 5. Connect

```
computer ssh mybox --tmux
```

Full environment, your repos, your secrets exported, tmux persists.

## Iterating on the flake

Edit any `home/*.nix`, push to your fork, `just switch mybox` again. The box fetches the new flake and reapplies.

For iteration without pushing:

```
computer sync ./ --computer mybox
computer ssh mybox -- 'nix run nixpkgs#home-manager -- switch \
  --flake path:/home/node/computer-nix#computer -b backup --no-write-lock-file'
```

## Re-onboarding another box

```
just go otherbox
```

Same flow. `secrets.json` is reused (secrets are stable across tasks). `repos.json` gets re-picked — that's the point.
