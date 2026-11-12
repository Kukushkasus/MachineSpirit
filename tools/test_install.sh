#!/usr/bin/env bash
# [ PURITY SEAL ] Install only inside a disposable home.
set -euo pipefail
root=$(cd -- "$(dirname -- "$0")/.." && pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
export HOME="$work/home" XDG_CONFIG_HOME="$work/config" XDG_DATA_HOME="$work/data" XDG_STATE_HOME="$work/state"
mkdir -p "$HOME"
unset HYPRLAND_INSTANCE_SIGNATURE
export GSETTINGS_BACKEND=memory   # the installer runs ms-cursor: keep gsettings off the real desktop
"$root/install.sh" --components shell --dry-run > "$work/dry-run.log"
test ! -e "$XDG_CONFIG_HOME"
"$root/install.sh" --components shell --no-packages --no-system --yes > "$work/install.log"
printf '\n// user edit\n' >> "$XDG_CONFIG_HOME/quickshell/machinespirit/shell.qml"
"$root/install.sh" update --no-packages --no-system --yes > "$work/update.log"
grep -q 'user edit' "$XDG_CONFIG_HOME/quickshell/machinespirit/shell.qml"
"$root/install.sh" uninstall --no-system --yes > "$work/uninstall.log"
grep -q 'user edit' "$XDG_CONFIG_HOME/quickshell/machinespirit/shell.qml"
test ! -e "$HOME/.local/bin/ms-settings"
# Installing again after uninstall must restore every removed file instead of treating them as user deletions.
"$root/install.sh" --components shell --no-packages --no-system --yes > "$work/reinstall.log"
test -x "$HOME/.local/bin/ms-settings"
test -s "$XDG_CONFIG_HOME/quickshell/machinespirit/shell.qml"
# The edit the previous uninstall preserved is replaced on reinstall, but must survive in the backup.
if grep -q 'user edit' "$XDG_CONFIG_HOME/quickshell/machinespirit/shell.qml"; then echo 'FAIL: the preserved edit was not replaced on reinstall'; exit 1; fi
grep -rq 'user edit' "$XDG_STATE_HOME/machinespirit/install"
echo 'PASS: dry-run, install, update, uninstall, reinstall and preservation'
