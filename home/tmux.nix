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
      set -ga terminal-overrides ",xterm-256color:RGB"

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
}
