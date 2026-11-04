#!/usr/bin/env bash
# [ PURITY SEAL ] Install only inside a disposable home.
set -euo pipefail
root=$(cd -- "$(dirname -- "$0")/.." && pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
export HOME="$work/home" XDG_CONFIG_HOME="$work/config" XDG_DATA_HOME="$work/data" XDG_STATE_HOME="$work/state"
mkdir -p "$HOME"
unset HYPRLAND_INSTANCE_SIGNATURE
"$root/install.sh" --components shell --dry-run > "$work/dry-run.log"
test ! -e "$XDG_CONFIG_HOME"
"$root/install.sh" --components shell --no-packages --no-system --yes > "$work/install.log"
printf '\n// user edit\n' >> "$XDG_CONFIG_HOME/quickshell/machinespirit/shell.qml"
"$root/install.sh" update --no-packages --no-system --yes > "$work/update.log"
grep -q 'user edit' "$XDG_CONFIG_HOME/quickshell/machinespirit/shell.qml"
"$root/install.sh" uninstall --no-system --yes > "$work/uninstall.log"
grep -q 'user edit' "$XDG_CONFIG_HOME/quickshell/machinespirit/shell.qml"
echo 'PASS: dry-run, install, update, uninstall and preservation'
