## computer nix

- nix config
- justfile with commands like :
  - `just create`, `just top`
- goal is to have a way to create computers easily, use fzf to show clean pickers for repo selection and agent selection maybe
- all commands of this nix config live in justfile
- repo layout will be clean nix layout simliar to /github/nix

- we will think about how to integrate the justfile really well with the computer cli for good workflows (i will think of htese based on my needs)

- we will port all the base clean config packages from /github/nix like the shell tools and bitwarden and shit allthe other nice things as well

- the idea basically is that this new repo computer-nix is a justfile with hostswapable nix configraiotns so u can also set the nix config to ur own git repo nix config and commands and shit
  and not use the given nix config but it lets u privion a mchine with agent-computer with nix and shows picker for repos to clone using gh cli and secrets to clone as well using bitwarden fzf picker

- flow iwll be create machine choose repos to clone, ur nix config nvim and all the other shit is already there. also use computer-codex login to copy over creds easily as well as for claude (show picker for this)

and overall just be a great expeirence for using nix with agentfomcputer to create disposable worksapce where u can easily ssh + tmux in using comptuer ssh --tmux and wotk continuiosly on projects and have ur whole workspace wtih you
