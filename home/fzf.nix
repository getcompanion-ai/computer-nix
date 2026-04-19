{
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    defaultCommand = "fd --type f --hidden --follow --exclude .git";
    defaultOptions = [
      "--height 40%"
      "--layout reverse"
      "--border"
      "--color=fg:#d4be98,bg:#181818,hl:#5b84de"
      "--color=fg+:#d4be98,bg+:#1e1e1e,hl+:#5b84de"
      "--color=info:#8ec97c,prompt:#5b84de,pointer:#d4be98,marker:#8ec97c,spinner:#d4be98"
    ];
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };
}
