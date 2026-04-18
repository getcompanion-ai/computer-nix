{
  programs.lazygit = {
    enable = true;
    settings = {
      gui.theme.activeBorderColor = [ "#9ece6a" "bold" ];
      gui.theme.inactiveBorderColor = [ "#565f89" ];
      gui.showFileTree = true;
      git.paging = {
        colorArg = "always";
        pager = "delta --paging=never";
      };
    };
  };
}
