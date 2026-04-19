# Forking

This doc is the technical map of the repo so you know what to touch when you adapt it.

## Repo tree

```
.
├── flake.nix                  home-manager + nvim-config inputs, x86_64-linux only
├── justfile                   all user-facing commands; `just go` is the entrypoint
├── .env.example               FLAKE_REF, COMPUTER_SIZE
├── skills.nix                 declarative list of agent skills installed on the box
├── secrets.example.json       schema for ./secrets.json (gitignored by default)
├── repos.example.json         schema for ./repos.json   (gitignored by default)
│
├── home/                      home-manager modules — one per concern
│   ├── default.nix            imports every other module here
│   ├── packages.nix           tools installed into $PATH
│   ├── aliases.nix            shell aliases
│   ├── zsh.nix                zsh config, sources ~/.config/secrets/shell.zsh
│   ├── prompt.nix             pure-prompt colors + eager SSH color resolution
│   ├── nvim.nix               programs.neovim, pulls ${inputs.nvim-config}/config/nvim
│   ├── git.nix                programs.git + programs.delta
│   ├── gh.nix                 gh binary; config.yml seeded writable (not a Nix symlink)
│   ├── ssh.nix                SSH client defaults (matchBlocks."*")
│   ├── tmux.nix               tmux
│   ├── fzf.nix                fzf
│   ├── bat.nix                bat
│   ├── eza.nix                eza (icons=never for broad terminal compat)
│   ├── lazygit.nix            lazygit
│   └── skills.nix             reads ../skills.nix and runs `npx skills add`
│                              during activation (content-addressed stamp)
│
├── scripts/                   implementation behind the justfile
│   ├── bootstrap.sh           installs Nix, starts nix-daemon, runs home-manager switch
│   ├── pick-handle.sh         fzf over `computer ls` (tempfile-staged, TTY-safe)
│   ├── auth-apply.sh          pipes `gh auth token` into `gh auth login --with-token` on box
│   ├── secrets-init.sh        gum fuzzy multi-select → writes ./secrets.json
│   ├── secrets-apply.sh       reads ./secrets.json, resolves bw/env/gh-cli,
│   │                          renders shell.zsh (0600), syncs to the box
│   ├── repos-init.sh          gum fuzzy multi-select over `gh repo list` → ./repos.json
│   ├── repos-apply.sh         clone-or-fast-forward every entry in ./repos.json
│   ├── pick-agent.sh          fzf pick claude/codex/both → `computer {claude,codex}-login`
│   ├── pick-repos.sh          legacy fzf picker (pre-declarative; still works)
│   └── pick-secrets.sh        legacy fzf picker (pre-declarative; still works)
│
└── docs/
    ├── forking.md             this file
    └── walkthrough.md         zero-to-box with explanation of each step
```

## What to change for a fork

| change | file |
| --- | --- |
| flake target | `.env` → `FLAKE_REF=github:<you>/my-computer-nix#computer` |
| default box size | `.env` → `COMPUTER_SIZE` |
| which tools are on the box | `home/packages.nix` |
| shell aliases | `home/aliases.nix` |
| prompt colors | `home/prompt.nix` (zstyle blocks at the top) |
| your neovim / dotfiles | `flake.nix` → `inputs.nvim-config.url` |
| agent skills installed | `skills.nix` at repo root |
| default clone root | `repos.example.json` → `"root"` |

## How the flake wires together

```
flake.nix
  ├── inputs.nixpkgs
  ├── inputs.home-manager
  └── inputs.nvim-config          (your dotfiles; flake = false)
        │
        ▼
  homeConfigurations.computer
        = home-manager.lib.homeManagerConfiguration {
            pkgs    = nixpkgs.legacyPackages.x86_64-linux;
            modules = [ ./home/default.nix ];
          }

home/default.nix
  imports every home/*.nix module. Adding a new module
  = create home/foo.nix + add `./foo.nix` to the imports list.
```

## How `just go` wires together

```
just go <handle>
  └── scripts/pick-handle.sh       ← pick once, use everywhere
        │
        ▼
  scripts/bootstrap.sh             ← nix install + home-manager switch
        │
        ▼  (skip if ~/.cache/computer-nix/auth.done)
  scripts/auth-apply.sh            ← gh auth on box
        │
        ▼  (skip if ~/.cache/computer-nix/secrets.done)
  scripts/secrets-init.sh          ← only if no ./secrets.json yet
  scripts/secrets-apply.sh         ← push secrets shell.zsh (0600)
        │
        ▼  (skip if ~/.cache/computer-nix/agent.done)
  computer claude-login / codex-login
        │
        ▼  (always)
  scripts/repos-init.sh            ← fuzzy picker (pre-selects last deploy)
  scripts/repos-apply.sh           ← clone or fast-forward each repo
```

Markers on the box live in `~/.cache/computer-nix/*.done`. Wipe them with `just go <handle> force` or `computer ssh <handle> -- rm -rf ~/.cache/computer-nix`.

## Sourcing your own nvim / zsh / dotfiles

```nix
# flake.nix
inputs.nvim-config = {
  url  = "github:<you>/<your-dotfiles>";
  flake = false;
};
```

`home/nvim.nix` reads `${inputs.nvim-config}/config/nvim` (adjust the path if your dotfiles layout differs). Run `nix flake update nvim-config` to repin.

## Adding a new home-manager module

1. Create `home/<tool>.nix` as a flat attrset — no header comment, match existing style.
2. Add `./<tool>.nix` to the imports list in `home/default.nix`.
3. `just switch <box>` to apply.

## Adding a new onboarding step

1. Write `scripts/<step>-apply.sh` taking `<handle>` as `$1`.
2. Add a recipe to the justfile that calls it via `pick-handle.sh`.
3. If it's expensive and one-shot, wire it into `just go` behind a marker check (`done_on_box <step>` / `mark_done <step>`). If it's per-task (like repos), call it unconditionally.
