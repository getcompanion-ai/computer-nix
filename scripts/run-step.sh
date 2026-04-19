#!/usr/bin/env bash
# Run a step with a live-updating spinner + elapsed timer + current sub-phase.
# Capture output to a per-run log file. Only surface the log if the step fails.
#
#   scripts/run-step.sh "1/5" "switch" ./scripts/bootstrap.sh capacity
set -euo pipefail

label="$1"; shift
title="$1"; shift
cmd_str="$*"

log_root="${COMPUTER_NIX_LOG_DIR:-${TMPDIR:-/tmp}/computer-nix}"
mkdir -p "$log_root"
ts="$(date +%Y%m%d-%H%M%S)"
slug="$(printf '%s' "$title" | tr -cs 'A-Za-z0-9' '-' | tr '[:upper:]' '[:lower:]' | sed 's/-$//')"
log="$log_root/${ts}-${slug}.log"
: >"$log"

prefix="[${label}]"
start=$(date +%s)

report_ok() {
  printf '  \033[32m✓\033[0m %s %s · %ds\n' \
    "$prefix" "$title" "$(( $(date +%s) - start ))"
}
report_fail() {
  local rc=$1
  printf '  \033[31m✗\033[0m %s %s · %ds (exit %d)\n' \
    "$prefix" "$title" "$(( $(date +%s) - start ))" "$rc"
  echo "     log: $log"
  echo "     command: $cmd_str"
  if [[ -s "$log" ]]; then
    echo "     --- last 60 lines ---"
    tail -60 "$log" | sed 's/^/     /'
  else
    echo "     (log is empty)"
  fi
}

# Heuristic: inspect the tail of the log and map it to a human-friendly phase
# string. Patterns are tuned to what bootstrap.sh / home-manager / nix emit.
phase_for_log() {
  local last
  last="$(tail -80 "$log" 2>/dev/null || true)"
  case "$last" in
    *"Starting Home Manager activation"*|*"Activating "*)         echo "activating home-manager" ;;
    *"evaluating derivation"*|*"evaluating file"*)                echo "evaluating flake" ;;
    *"building '"*|*"builder for"*)                               echo "building packages" ;;
    *"copying path"*|*"copying "*" from "*)                       echo "copying store paths" ;;
    *"unpacking source"*|*"unpacking channel"*)                   echo "unpacking sources" ;;
    *"fetching"*"github:"*|*"downloading "*)                      echo "downloading inputs" ;;
    *"nix daemon is up"*|*"starting nix daemon"*)                 echo "starting nix daemon" ;;
    *"Nix was installed successfully"*)                           echo "nix installed, applying flake" ;;
    *"nix-installer"*|*"Step: "*|*"Running self test"*)           echo "installing nix" ;;
    *"applying home-manager flake"*)                              echo "applying flake" ;;
    *"applying gh auth"*|*"gh auth"*)                             echo "configuring gh" ;;
    *"cloning "*|*"updating "*|*"syncing "*"repo"*)               echo "cloning repos" ;;
    *"Transferring"*|*"Preparing file transfer"*)                 echo "transferring files" ;;
    *"Preparing SSH"*|*"Connecting to "*)                         echo "connecting" ;;
    "")                                                           echo "starting" ;;
    *)                                                            echo "working" ;;
  esac
}

rc_file="$(mktemp)"
trap 'rm -f "$rc_file"' EXIT

# Launch command.
(
  set +e
  "$@" >"$log" 2>&1
  echo $? >"$rc_file"
) &
cmd_pid=$!

if [[ -t 1 ]]; then
  # Hide cursor for a clean redraw.
  printf '\033[?25l'
  trap 'printf "\033[?25h"; rm -f "$rc_file"' EXIT INT TERM
  spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
  i=0
  while kill -0 "$cmd_pid" 2>/dev/null; do
    elapsed=$(( $(date +%s) - start ))
    phase="$(phase_for_log)"
    frame="${spin:$((i % ${#spin})):1}"
    # \r + clear-to-end-of-line, then print fresh status.
    printf '\r\033[K  \033[36m%s\033[0m %s %s · %s · %ds' \
      "$frame" "$prefix" "$title" "$phase" "$elapsed"
    i=$((i + 1))
    sleep 0.2
  done
  # Clear the spinner line before the final ✓/✗.
  printf '\r\033[K'
  printf '\033[?25h'
fi

wait "$cmd_pid" 2>/dev/null || true
rc="$(cat "$rc_file" 2>/dev/null || echo 1)"

if [[ "$rc" == "0" ]]; then
  report_ok
else
  report_fail "$rc"
  exit "$rc"
fi
