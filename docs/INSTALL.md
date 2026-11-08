# Installation and recovery

## Requirements

- Arch Linux or CachyOS. Run the installer as your normal desktop user; it asks for `sudo` only for packages and system files.
- Python 3.11+ and Bash to start the installer, and `pacman` for packages (AUR is optional).
- Hyprland 0.55 or newer with the Lua configuration API (tested with 0.57) and Quickshell (tested with 0.3.2). Older Hyprland releases that only read the Hyprlang format are not supported.
- Keep an existing working login method available: the installer does not change your login shell or display manager.

## Install

```sh
./install.sh                        # component menu, including full installation
./install.sh --full --dry-run       # inspect; no files or packages changed
./install.sh --full                 # all components; asks before changing GRUB/Plymouth
./install.sh --full --with-boot     # same, and include the boot theme without asking
./install.sh --components boot      # only the boot theme (explicit choice)
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

The shell is included with every selection. `--no-packages` skips pacman for an already provisioned machine. `--yes` accepts the displayed installation without an interactive prompt. `--with-aur` additionally installs the optional Darkly theme using an existing paru/yay.

Start Hyprland through your existing login method. Your existing `hyprland.lua` is backed up when the Hyprland component replaces it. Shell-only installations must start `~/.local/bin/ms-session start` from their own compositor session; use the supplied Hyprland configuration for the complete keybinding and display integration.

## Updating

### From Settings or `ms-update` (releases)

**Settings, Updates** (or `ms-update` in a terminal) checks the latest published release on GitHub. Nothing is checked by itself: a request is sent only when you press the refresh button, and only if the Privacy permission "Update checks" allows it (the default is *On request*; Local only mode blocks it). **Update dots** opens a terminal that downloads the release archive and `SHA256SUMS`, shows the changelog and asks before it runs the normal installer, with backups and rollback. Packages are installed through pacman as usual, so it may ask for your password. The boot theme is never touched by an update.

```sh
ms-update status                                   # installed and last known version, no network
ms-update check                                    # ask GitHub for the latest release
ms-update install                                  # download, check, review, install
ms-update install --from-file MachineSpirit-X.Y.Z.tar.gz   # offline: SHA256SUMS must sit next to the archive
ms-update install --dry-run                        # check the archive and show the changelog only
```

What is checked: the archive must match its entry in `SHA256SUMS`, unpack as regular files under one folder within size limits, and its release tag, file name and inner `VERSION` must agree, otherwise nothing is installed. The checksum only protects against a damaged download: the file comes from the same release, so it cannot prove who published it, and releases are not signed. Going back to an older version needs `--force` and an explicit answer.

### From a Git checkout

```sh
git pull
./install.sh update --dry-run
./install.sh update
```

Selected components are remembered. Both ways use the same installer, so the rules below apply to each.

## Backups and recovery

Every installation is a transaction recorded under `$XDG_STATE_HOME/machinespirit/install/` (default `~/.local/state/machinespirit/install/`). It keeps the original files and symlinks, permissions and the hashes of what was installed. Generated theme files use the same format.

- **Your edits are preserved.** Updates keep files you changed since they were installed and list their paths; merge those by hand. Settings, widget positions and notes are never reset.
- **Files a new version no longer ships** are removed only when MachineSpirit installed them, you did not change them and nothing in the new version refers to them. Otherwise they stay and a warning says why.
- **Failures roll back.** A failed installation restores every file it can and says what is left and how to retry. Package installations are not rolled back.
- **Interrupted installations** (crash, power loss) are recovered on the next installation, and only when the process that wrote the record is provably gone. `doctor` reports unfinished records and who owns them.
- **Nothing is discarded silently.** Restore and uninstall keep files whose hashes no longer match the installed version and report them. Generated state, notes, API keys and wallpaper downloads remain after uninstall. Stop the shell before uninstalling it.

```sh
./install.sh doctor                 # check commands, versions, settings and unfinished records
./install.sh restore BACKUP_ID      # guarded restore of one transaction
./install.sh uninstall              # restore every recorded transaction
```

Keep the backup folder until you have verified a recovery.

## Boot component

Currently supported: GRUB + mkinitcpio and an existing console-based login. The installer adds Plymouth to recognized `HOOKS` arrays, selects the original theme, adds quiet/splash kernel arguments and regenerates initramfs/GRUB. Existing display managers are preserved and cause this component to stop before installation. Choose the other components on unsupported systems.

Existing autologin is kept; autologin is never enabled automatically. Password-based console login remains password-based. Plymouth supports password prompts. The shell startup overlay is decorative, not a lock screen. Hardware/firmware mode switches may still cause brief blank frames.

Boot backups are under `/var/lib/machinespirit/boot/`. To restore a specific boot backup from the source checkout:

```sh
sudo python3 installer/boot.py restore BACKUP_ID
```

Restore the boot component separately before uninstalling user files. Packages are not automatically removed.
