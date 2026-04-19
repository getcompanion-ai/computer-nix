{ lib, ... }:
{
  programs.tmux = {
    enable = true;
    baseIndex = 1;
    escapeTime = 10;
    keyMode = "vi";
    mouse = true;
    terminal = "tmux-256color";
    historyLimit = 50000;

    extraConfig = ''
      set -g renumber-windows on
      set -g focus-events on

      # Truecolor passthrough for whichever terminal the user is driving from.
      # We list every $TERM the box might see — the override is harmless if
      # the terminfo entry isn't installed.
      set -ga terminal-overrides ",xterm-256color:RGB"
      set -ga terminal-overrides ",xterm-ghostty:RGB"
      set -ga terminal-overrides ",alacritty:RGB"
      set -ga terminal-overrides ",wezterm:RGB"

      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"
      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R

      set -g status-style "bg=default,fg=#a9b1d6"
      set -g status-left "#[fg=#7aa2f7,bold] #S "
      set -g status-right "#[fg=#565f89] %Y-%m-%d %H:%M "
      set -g window-status-current-style "fg=#9ece6a,bold"
    '';
  };

  # Many terminal emulators ship a custom $TERM (xterm-ghostty, xterm-kitty,
  # etc.) whose terminfo entry isn't installed on a remote box. When the user
  # types `tmux`, tmux tries to look up that entry and fails with
  # "missing or unsuitable terminal".
  #
  # Transparently sanitize $TERM to a universally-installed value just for the
  # tmux invocation. If the correct terminfo is present we leave it alone.
  programs.zsh.initContent = lib.mkAfter ''
    tmux() {
      if [ -n "$TERM" ] && ! command infocmp "$TERM" >/dev/null 2>&1; then
        TERM=xterm-256color command tmux "$@"
      else
        command tmux "$@"
      fi
    }
  '';
}
