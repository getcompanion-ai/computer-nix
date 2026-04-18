{
  programs.ssh = {
    enable = true;
    compression = true;
    serverAliveInterval = 30;
    serverAliveCountMax = 3;
    controlMaster = "auto";
    controlPath = "~/.ssh/cm-%r@%h:%p";
    controlPersist = "10m";
  };
}
