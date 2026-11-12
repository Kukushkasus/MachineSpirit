# Installation and recovery

## Requirements

- Arch Linux or CachyOS. Run the installer as your normal desktop user; it asks for `sudo` only for packages and system files.
- Python 3.11+ and Bash to start the installer, and `pacman` for packages (AUR is optional).
- Hyprland 0.55 or newer with the Lua configuration API (tested with 0.57) and Quickshell (tested with 0.3.2). Older Hyprland releases that only read the Hyprlang format are not supported.
- Keep an existing working login method available. The installer never replaces or reconfigures a display manager you already use; it sets up SDDM only on a machine that has none (see [Login screen](#login-screen)).

## Install

```sh
./install.sh --full --yes           # everything, no questions (the quick install)
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
| login | SDDM with the MachineSpirit theme, only when no login manager is present; optional autologin |
| boot | Plymouth theme and GRUB/mkinitcpio integration |

The shell is included with every selection. `--no-packages` skips pacman for an already provisioned machine. `--yes` accepts the displayed installation without an interactive prompt. `--with-aur` additionally installs the optional Darkly theme using an existing paru/yay.

Your existing `hyprland.lua` is backed up when the Hyprland component replaces it. Shell-only installations must start `~/.local/bin/ms-session start` from their own compositor session; use the supplied Hyprland configuration for the complete keybinding and display integration.

### Two ways to run it

Both use the same command, `./install.sh --full --yes`.

- **From a text console** (a fresh Arch or CachyOS with no desktop): log in, clone the repository, run it. No display, Wayland or Hyprland variables are needed. Packages, files and the login screen are set up; nothing graphical is started. Reboot and sign in through SDDM with the Hyprland session.
- **From a running Hyprland session**, in any terminal: the installer changes files and packages only. It does not close or restart the session, the shell or any window. Apply the new shell at once with `ms-session restart` from inside the session, or reboot.

## Login screen

The `login` component is part of `--full`. Before it changes anything it checks the machine, and it stops with the fix when something is missing (for example the Hyprland session file or the `sddm` package).

| Situation | What happens |
|---|---|
| No display manager | SDDM is installed, enabled (not started) and given the MachineSpirit theme. The theme is switched on only after the SDDM greeter has loaded it; if it does not load, the default SDDM theme stays and the installer says so. |
| SDDM is already your display manager | Nothing is changed: its configuration and theme stay. Choose the Hyprland session (not UWSM) at its login screen. |
| Another display manager (GDM, LightDM, greetd, ly, ...) | Nothing is changed and SDDM is not installed next to it. The installer prints which session to choose. |
| SDDM that MachineSpirit set up earlier | The theme is kept up to date on update; nothing else is touched. |

An SDDM theme you chose yourself is never replaced. Files are written to `/etc/sddm.conf.d/machinespirit.conf` and `/usr/share/sddm/themes/machinespirit/`, with a backup in `/var/lib/machinespirit/login/`. `./install.sh uninstall` puts them back and disables `sddm.service` if the installer enabled it; packages stay. To undo one change only: `sudo python3 installer/login.py restore BACKUP_ID`.

### Autologin

Off by default. It is enabled with `--with-autologin`, or by answering yes to the question in an interactive `--full`. It writes `/etc/sddm.conf.d/machinespirit-autologin.conf` (your user and the Hyprland session); delete that file to ask for a password again. An autologin that is already configured is not overridden. With autologin, the lock screen is what protects the session: it still locks after idle time, on **Super+L** and on sleep, but not at boot, so anyone who can switch the computer on gets the desktop.

## Lock screen

The shell draws its own lock screen (Quickshell session lock, passphrase checked through PAM with the `hyprlock` service from the hyprlock package). `ms-session lock`, **Super+L**, the idle timer and sleep all use it. It reports the screen as locked only after the compositor has confirmed it. If the shell crashes while the screen is locked, the screen stays locked, the session supervisor starts the shell again and the new shell takes the lock over, so the passphrase is still required.

While the screen is locked, `ms-session restart`, `./install.sh` (install, update, restore, uninstall) and `ms-update install` refuse to run and say so before anything changes, and the shell does not reload its files; unlock first, then repeat. hyprlock is the fallback. It is used automatically only when the shell is not running and nothing is locked; it is never started on top of a lock that is held. To use it always, set `"lockBackend": "hyprlock"` in `settings.json`. If both the shell and the supervisor are gone while the screen is locked, the screen stays locked (Hyprland shows its own recovery screen). Start the shell again with `ms-session start` from another console, with the session's environment: it takes the lock over and asks for the passphrase. The recovery screen lists Hyprland's own command as well; follow those instructions.

## Updating

### From Settings or `ms-update` (releases)

**Settings, Updates** (or `ms-update` in a terminal) checks the latest published release on GitHub. Nothing is checked by itself: a request is sent only when you press the refresh button, and only if the Privacy permission "Update checks" allows it (the default is *On request*; Local only mode blocks it). **Update dots** opens a terminal that downloads the release archive and `SHA256SUMS`, shows the changelog and asks before it runs the normal installer, with backups and rollback. Packages are installed through pacman as usual, so it may ask for your password. The boot theme is never touched by an update, from Settings or from a checkout; refresh it with `./install.sh --components boot`.

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
- **Nothing is discarded silently.** Restore and uninstall keep files whose hashes no longer match the installed version and report them. Generated state, notes, API keys and wallpaper downloads remain after uninstall; the generated MachineSpirit cursor themes are removed and the cursor you had before is set again. Stop the shell before uninstalling it.

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
