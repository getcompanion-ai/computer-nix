{ config, lib, pkgs, ... }:
{
  programs.zsh = {
    enable = true;
    dotDir = config.home.homeDirectory;
    enableCompletion = false;
    defaultKeymap = "viins";

    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    history = {
      size = 50000;
      save = 50000;
      ignoreDups = true;
      ignoreAllDups = true;
      ignoreSpace = true;
      extended = true;
      append = true;
      path = "${config.xdg.stateHome}/zsh_history";
    };

    envExtra = ''
      if [[ -f "$HOME/.cargo/env" ]]; then
        . "$HOME/.cargo/env"
      fi
      export NODE_NO_WARNINGS=1
      export MANPAGER="nvim +Man!"
    '';

    initContent = lib.mkMerge [
      (lib.mkOrder 550 ''
        autoload -U compinit && compinit -d "${config.xdg.stateHome}/zcompdump" -u
        zmodload zsh/complist
        zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-za-z}'
      '')

      (lib.mkOrder 1000 ''
        if [[ -f ~/.config/secrets/shell.zsh ]]; then
          source ~/.config/secrets/shell.zsh
        elif [[ -f ~/.secrets ]]; then
          source ~/.secrets
        fi

        [ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"
        export BUN_INSTALL="$HOME/.bun"

        typeset -U path PATH
        path=(
          "$HOME/.bun/bin"
          "$HOME/.local/bin"
          "$HOME/.nix-profile/bin"
          "/etc/profiles/per-user/${config.home.username}/bin"
          "/nix/var/nix/profiles/default/bin"
          $path
        )

        autoload -Uz add-zle-hook-widget
        _cursor() { printf '\e[%s q' "''${1:-6}"; }
        _cursor_select() { [[ "$KEYMAP" == vicmd ]] && _cursor 2 || _cursor 6; }
        _cursor_beam() { _cursor 6; }
        add-zle-hook-widget zle-keymap-select _cursor_select
        add-zle-hook-widget zle-line-init _cursor_beam
        add-zle-hook-widget zle-line-finish _cursor_beam

        precmd() { _cursor_beam; }
        preexec() { _cursor_beam; }
      '')

      (lib.mkAfter ''
        bindkey '^k' forward-char
        bindkey '^j' backward-char
      '')
    ];
  };
}
