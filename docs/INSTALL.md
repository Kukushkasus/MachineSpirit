# Installation and recovery

Run as your normal desktop user on Arch Linux or CachyOS. Python 3.11+ and Bash are required to start the installer. Runtime testing uses Hyprland 0.57.0 and Quickshell 0.3.2; older Hyprlang-only releases are not supported. Keep an existing working login method available.

```sh
./install.sh                        # component menu, including full installation
./install.sh --full --dry-run       # inspect; no files or packages changed
./install.sh --full                 # all components, including boot
./install.sh --components shell,hyprland,terminal,apps,lock,wallpapers
```

| Component | Installs |
|---|---|
| shell | Quickshell configuration, helpers, fonts and theme engine |
| hyprland | Compositor configuration and default keybindings |
| terminal | Kitty, fish integration and fastfetch |
| apps | Dependencies and opt-in GTK/Qt palette generation |
| lock | Hyprlock and managed Hypridle timeouts |
| wallpapers | Three original starter wallpapers |
| boot | Plymouth theme and GRUB/mkinitcpio integration |

The shell is included with every selection. `--no-packages` skips pacman for an already provisioned machine. `--yes` accepts the displayed installation without an interactive prompt. `--with-aur` additionally installs optional Darkly using an existing paru/yay; the default does not require AUR.

The installer does not change your login shell. Start Hyprland through your existing login method. Your existing `hyprland.lua` is backed up when the Hyprland component replaces it. Shell-only installations require you to start `~/.local/bin/ms-session start` from your compositor session; use the supplied Hyprland configuration for the complete keybinding and display integration.

## Boot component

Currently supported: GRUB + mkinitcpio and an existing console-based login. The installer adds Plymouth to recognized `HOOKS` arrays, selects the original theme, adds quiet/splash kernel arguments and regenerates initramfs/GRUB. Existing display managers are preserved and cause this component to stop before installation. Choose the other components on unsupported systems.

Existing autologin is kept; autologin is never enabled automatically. Password-based console login remains password-based. Plymouth supports password prompts. The shell startup overlay is decorative, not a lock screen. Hardware/firmware mode switches may still cause brief blank frames.

Boot backups are under `/var/lib/machinespirit/boot/`. To restore a specific boot backup from the source checkout:

```sh
sudo python3 installer/boot.py restore BACKUP_ID
```

Restore the boot component separately before uninstalling user files. Packages are not automatically removed.

## Updates and backups

```sh
./install.sh update --dry-run
./install.sh update
./install.sh doctor
./install.sh restore BACKUP_ID
./install.sh uninstall
```

Use the new source checkout for updates. Selected components are remembered. Each user-file transaction lives under `$XDG_STATE_HOME/machinespirit/install/` (default `~/.local/state/machinespirit/install/`). It records original files/symlinks, permissions and installed hashes. Generated theme files use the same transaction format.

Updates preserve files changed since the recorded installation and report their paths. Merge changes to those files manually. Settings, widget positions and notes are not reset. A failed user-file transaction restores its originals. Package downloads/installations are not rolled back.

Restore and uninstall preserve files whose hashes no longer match the installed version, reporting them rather than discarding changes. Backups remain available for manual recovery. Generated state, notes, API keys and wallpaper downloads remain after uninstall. The shell should be stopped before uninstalling it.

Unfinished records marked `applying` indicate interruption. Inspect their manifest and original copies; run `restore BACKUP_ID` for a guarded restoration. Do not delete the backup directory until you have verified recovery.

## Checks

```sh
python3 -m unittest discover -s tools -p 'test*.py'
bash tools/test_install.sh
```

No command in these checks installs packages on the host. The installation smoke test uses disposable HOME/XDG directories.
