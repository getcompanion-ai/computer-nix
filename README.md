## Computer Nix

<img width="3598" height="630" alt="Gemini_Generated_Image_d10lsxd10lsxd10l" src="https://github.com/user-attachments/assets/332ca256-2707-46af-b593-e5e3071a2263" />

A minimal home-manager flake and justfile for running machines on [agentcomputer](https://agentcomputer.ai).

<img width="600" height="400" alt="image" src="https://github.com/user-attachments/assets/e4dfe881-6999-4dc6-b762-d164e99fdd79" />


The flake composes home-manager on `x86_64-linux` only.

Global username, flake ref, clone path, and box size are encoded in `.env`.

Claude and Codex are preinstalled on the computer image. `just agent` copies
local credentials onto the box via `computer claude-login` and `computer codex-login`.

## Quickstart

```
gh repo create my-computer-nix --template getcompanion-ai/computer-nix --public --clone
cd my-computer-nix
cp .env.example .env

# one-time: generate declarative manifests for your secrets and repos
just secrets-init      # writes secrets.json
just repos-init        # writes repos.json

computer create --size ram-4g mybox
just go mybox          # bootstrap + gh auth + secrets + repos + agent creds
computer ssh mybox --tmux
```

## Commands

```
just go          one-shot: switch + auth + secrets + repos + agent creds
just switch      apply the home-manager flake to a box
just auth        push laptop-side gh auth onto the box (for private repos)
just secrets     declaratively apply ./secrets.json
just secrets-init  first-run gum picker → writes ./secrets.json
just repos       declaratively apply ./repos.json
just repos-init  first-run gum picker → writes ./repos.json
just agent       copy claude / codex credentials
just create      create a box using COMPUTER_SIZE from .env
```

Every command that targets a box accepts a `<handle>` or prompts an fzf picker
over `computer ls`.

## Declarative manifests

`secrets.json` and `repos.json` are the source of truth for what gets pushed to
every box. They live at the repo root, and examples are provided as
`secrets.example.json` / `repos.example.json`. Both files are `.gitignore`-d by
default — commit them to your fork with `git add -f` if you want them versioned.

### `secrets.json`

```json
{
  "bitwarden": { "folder": "machine secrets" },
  "env": {
    "OPENAI_API_KEY":  { "bw": "OpenAI API Key" },
    "ANTHROPIC_API_KEY": { "bw": "Anthropic API Key" },
    "GITHUB_TOKEN":    { "fallback": "gh-cli" },
    "VERCEL_TOKEN":    { "envName": "VERCEL_TOKEN" }
  },
  "files": [
    { "src": "~/.aws/credentials", "dest": "~/.aws/credentials", "mode": "0600" }
  ]
}
```

Each `env` entry can resolve from:
- `bw`: Bitwarden item name (looked up in the declared folder)
- `envName`: an env var on your laptop
- `fallback: "gh-cli"`: uses `gh auth token` (for `GITHUB_TOKEN`)

`files` entries are pushed verbatim with the given mode. `computer sync` is
used for the transfer.

Output on the box lives at `~/.config/secrets/shell.zsh` (mode `0600`) and is
sourced automatically at shell startup.

### `repos.json`

```json
{
  "root": "~/work",
  "repos": [
    { "repo": "getcompanion-ai/computer-nix", "branch": "main" },
    { "repo": "you/your-private-repo", "dest": "~/work/secret", "depth": 1 }
  ]
}
```

`just repos` clones missing repos and fast-forwards existing ones to the
declared branch. Private repos work because `just auth` has already pushed your
`gh` token.

## Forking

Edit `.env` for `FLAKE_REF`, `COMPUTER_SIZE`.
Edit `home/packages.nix` to add or remove tools.
Edit `home/aliases.nix` to own your shell aliases.
Point `inputs.nvim-config` at your own dotfiles repo in `flake.nix`.

See [docs/forking.md](docs/forking.md) for the Claude prompt to adapt this template to your daily-driver machine.

## Prereqs

```
computer   — https://agentcomputer.ai/install.sh
gh         — authenticated with `gh auth login`
bw         — authenticated with `bw login && bw unlock` (only if using Bitwarden)
just       — package manager of choice
gum        — brew install gum (used by *-init pickers)
jq         — package manager of choice
fzf        — package manager of choice
```
