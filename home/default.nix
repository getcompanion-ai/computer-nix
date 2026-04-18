{ username, ... }:
{
  imports = [
    ./packages.nix
    ./aliases.nix
    ./zsh.nix
    ./prompt.nix
    ./nvim.nix
    ./tmux.nix
    ./git.nix
    ./gh.nix
    ./fzf.nix
    ./bat.nix
    ./eza.nix
    ./lazygit.nix
    ./ssh.nix
  ];

  home.username = username;
  home.homeDirectory = "/home/${username}";
  home.stateVersion = "24.11";

  programs.home-manager.enable = true;
  targets.genericLinux.enable = true;

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };
}
