{ pkgs, ... }:
{
  programs.git = {
    enable = true;
    package = pkgs.git;

    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      rebase.autoStash = true;
      fetch.prune = true;
      diff.algorithm = "histogram";
    };
  };

  programs.git.delta = {
    enable = true;
    options = {
      navigate = true;
      line-numbers = true;
      syntax-theme = "Nord";
    };
  };
}
