{
  config,
  lib,
  pkgs,
  ...
}:
let
  userSkills = (import ../skills.nix).skills or [ ];

  manifestHash = builtins.hashString "sha256" (builtins.toJSON userSkills);

  installCommands = lib.concatMapStringsSep "\n" (skill: ''
    echo "  installing skill: ${skill.name}"
    "${pkgs.nodejs_22}/bin/npx" -y skills add ${lib.escapeShellArg skill.source} \
      --skill ${lib.escapeShellArg skill.name} -g -y \
      || echo "  (failed to install ${skill.name}, continuing)"
  '') userSkills;

  missingChecks = lib.concatMapStringsSep "\n" (skill: ''
    if [ ! -e "$HOME/.agents/skills/${skill.name}" ]; then
      needs_sync=1
    fi
  '') userSkills;
in
{
  home.activation.ensureGlobalSkills = lib.hm.dag.entryAfter [ "writeBoundary" ] (
    if userSkills == [ ] then
      ''
        : # no skills configured
      ''
    else
      ''
        state_dir="${config.xdg.stateHome}/skills"
        stamp_file="$state_dir/global-skills-manifest.sha256"
        desired_hash=${lib.escapeShellArg manifestHash}
        needs_sync=0

        mkdir -p "$state_dir" "$HOME/.agents/skills"

        if [ ! -f "$stamp_file" ] || [ "$(cat "$stamp_file")" != "$desired_hash" ]; then
          needs_sync=1
        fi

        ${missingChecks}

        if [ "$needs_sync" -eq 1 ]; then
          export PATH="${
            lib.makeBinPath [
              pkgs.nodejs_22
              pkgs.git
              pkgs.coreutils
              pkgs.findutils
              pkgs.gnugrep
              pkgs.gnused
            ]
          }:$PATH"

          echo "==> syncing ${toString (builtins.length userSkills)} skill(s)"
          ${installCommands}

          printf '%s\n' "$desired_hash" > "$stamp_file"
        fi
      ''
  );
}
