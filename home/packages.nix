{ pkgs, ... }:
{
  home.packages = with pkgs; [
    zsh
    pure-prompt
    zsh-syntax-highlighting
    zsh-autosuggestions

    fzf
    ripgrep
    fd
    eza
    bat
    zoxide

    neovim
    tmux

    git
    gh
    lazygit
    delta                 # git diff pager

    bitwarden-cli         # `bw` — used by `just secrets`

    jq
    curl
    htop
  ];
}
