# Changelog

## 0.1.0 - 2026-11-08

First release.

### Added

- Desktop shell for Hyprland on Quickshell: bar, five movable desktop instruments, command console and workspace overview, control panel (Sanctum), notification archive, wallpaper archive, lock screen, optional original Plymouth boot theme, startup overlay and original wallpapers. Colours follow the wallpaper.
- Settings with live window preview, display arrangement with a 15-second confirmation and automatic rollback, keyboard, pointer, session and shortcut pages, persisted in `settings.json`. A searchable shortcut manual (**Super+/**) and conflict-checked shortcut overrides.
- First-launch setup with privacy presets, per-feature network permissions, optional authenticated proxy, and browser policies (telemetry, studies, crash uploads, suggestions, prefetch, proxy routing) applied through a root-owned helper after Polkit authorization. **Skip setup** finishes at once with safe defaults.
- **Updates** page and `ms-update`: check for a new release only when asked, then download, check against `SHA256SUMS`, review the changelog and install with backups. Works offline from a local archive. New Privacy permission "Update checks" (default: on request).
- Component installer with backups, guarded restore and uninstall, `doctor`, theme-file ownership records, recovery documentation and automated checks. Bilingual README and font licensing; GPL-3.0-only.
- Reduced-motion and low-power modes; short, consistent panel transitions.

### Changed

- `--full` no longer changes GRUB, mkinitcpio and Plymouth silently: the boot theme is asked about separately and skipped with `--yes` unless `--with-boot` is given. An update never touches the boot theme and keeps it recorded.
- The release archive is built from an explicit list of installable paths: no README media, tests or private files (about 1.6 MB instead of 16 MB). Only the PNG starter wallpapers are installed (their SVG sources no longer appear as duplicates in the wallpaper archive), and only the two tool scripts `ms-theme` uses.
- Wallpaper thumbnails load four at a time.
- Settings: more transparent panel that lightly dims the screen, usable on small screens (a scrolling icon rail and compact header below 520 px high or 700 px wide), controls ease between states, the unsaved-changes dialog fades, clearer wording for new users. The Browsers page lists only installed browsers and spells out the three steps (choose, review, confirm with password).
- Launcher hint, Sanctum link tiles and the network popup no longer cut off or obscure their text.

### Fixed

- Installer: installing again after `uninstall` or `restore` works; a failed installation rolls back every file it can, reports what is left and removes the browser-policy helper it added; a failed boot restore puts the boot files back; `update` writes no empty records; an installation killed half-way is recovered on the next run (only when its writer is provably gone, never an active one); files a new version no longer ships are removed only with proof and otherwise kept with a warning; `uninstall` leaves no bytecode and exits non-zero if something could not be restored.
- Settings no longer reopen in a loop when `settings.json` is damaged and the error explains how to recover; a late display-preview watchdog can no longer revert a newer preview; edits made during an in-flight save are preserved; a cancelled password prompt now says so.
- Privacy daemon: its `gost` now dies with it (also after `kill -9`), a stale `gost` is stopped at start, repeated quick failures back off, the session supervisor restarts the daemon and the proxy restarts when `gost` appears; proxy password feedback and port validation; a browser proxy policy is refused when `gost` is missing.
- Earlier: broad Quickshell termination, obsolete compositor dispatch calls, screenshot error reporting, launcher state shell interpolation, destructive Qt configuration replacement; guarded browser policy restoration when paths change; fewer hidden spectrum consumers.

### Security

- `ms-update` unpacks strictly (regular files and folders only, one top folder, size and entry limits, special permission bits dropped), requires `SHA256SUMS` to list the archive exactly once with a valid value, strips terminal control codes from release text, stops when the release tag, archive name and inner `VERSION` disagree, and needs `--force` plus an explicit answer to install an older version.
- Wallpaper API keys are passed over stdin and stored atomically with mode 0600; the remote image cache is pruned.
- Network access of the shell always follows the Privacy permissions; a failed proxy never falls back to a direct connection.

### Known limitations

- Tested in a QEMU/KVM guest. Physical hardware (NVIDIA, Bluetooth, DDC brightness), lock-screen PAM and suspend have not been tested.
- Releases are not signed: the checksum only catches a damaged download.
- The interface and the documentation are English only.
