# Declarative list of agent skills to install globally on the box.
#
# Each skill is passed to `npx skills add <source> --skill <name> -g -y` during
# home-manager activation (via ./home/skills.nix). The resulting skills live at
# ~/.agents/skills/<name> on the box and are available to any agent (Claude,
# Codex, etc.) that reads that directory.
#
# Only re-runs the installer when this list changes (content-addressed by hash).
#
# Add your own skills below, or leave empty to skip skill installation.
{
  skills = [
    # {
    #   name = "rams";
    #   source = "https://github.com/brianlovin/claude-config";
    # }
    # {
    #   name = "frontend-design";
    #   source = "https://github.com/anthropics/skills";
    # }
  ];
}
