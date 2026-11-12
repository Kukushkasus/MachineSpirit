# Changelog

## 0.6.0 - 2026-11-13

### Added

- Faction motion: large windows (Sanctum, the console, popups, Settings, the wallpaper archive, toasts) arrive with a moment of their own drawn over the housing, and their parts come up one after another in the faction's manner. Mechanicus: current runs round the frame while relays snap in and lamps warm. Ultramarines: a gold pulse runs the trim and instruments come up in strict order. Necrons: a phase line scans down the glass, glyphs flare, parts shimmer in. Khorne: a sheen of heat, a heavy landing with a jolt and sparks.
- The power wheel deploys its rites from the hub in turn (the Mechanicus wheel meshes like a gear); the console's sectors light one after another; Settings pages come up card by card; a new theme arrives with its own signal along the bar and in open panels.
- Necron conduits carry a slow drift of energy at rest.
- Cursor themes for all four factions (`MachineSpirit-Mechanicus`, `-Ultramarines`, `-Necrons`, `-Khorne`) in XCursor and hyprcursor form, with every standard shape and a light and dark double outline. Settings → Appearance → Cursor: follow the faction, keep the system cursor or name another theme; sizes 24 to 48; a preview on light, dark and wallpaper. New `ms-cursor` command; settings `cursorMode`, `cursorSize`, `cursorTheme`. A cursor set by hand in `hypr/local.lua` still wins at login. Drawing the themes needs `rsvg-convert` (librsvg); without `hyprcursor-util` only the XCursor form is made, without `rsvg-convert` the current pointer stays.

### Changed

- Shared motion timings in `Theme`: spring curves by faction character, longer entrances and shorter exits, a stagger step. Popups, the console, Settings, the wallpaper archive and toasts open on the faction's spring; toggles, segmented choices and buttons press in and spring back; the chosen option in a segmented choice slides to its place.
- Ultramarines bar: thinner plates and gold rim, a slim armour rail between the sections instead of a full-height band, smaller clamps and bolts. Click areas are unchanged.
- Small labels in Settings, Sanctum, popups and desktop instruments are at least 10 px (most 11 px).

### Fixed

- Signing out and in again: the previous session's supervisor outlived its Hyprland, kept restarting the shell into the next login and held the session lock, so the new login ran without its own idle lock. It now ends with its compositor, and the privacy daemon ends with it even when the supervisor is killed.
- Popups whose faction title is wider than their contents (the Necron calendar) had the contents pushed to the left with an empty strip on the right; they are now centred.
- Lock screen: the blurred wallpaper faded out towards the screen edges and the plain background showed through as a frame with rounded corners (most visible with Khorne). The picture is now blurred beyond the screen edge and clipped. The lock screen also gets a vignette, and Khorne a slow forge glow from below.

## 0.5.0 - 2026-11-12

Road to 1.0. Four complete faction liveries on one shell, a Settings Center that reaches every part of it, and new wallpapers.

### Added

- Four theme packs: Adeptus Mechanicus (still the default), Ultramarines, Necrons and Chaos: Khorne. Each redraws the whole shell, not only its accents: the bar's silhouette (plates clamped to the edge, one armour band, floating shards, toothed iron slabs), window housings and their glass, section cards and titles, keys, icon wells, level strips, switches and sliders, workspace marks, the console, the power wheel, popups and the way they hang from the bar, toasts, desktop instruments and the lock screen's housing. Each has its own motion, rare effects and display face (Cinzel, Michroma, Grenze Gotisch; OFL, shipped with the shell). One layout for all: no control moves and no click area shrinks.
- New 3840×2160 wallpapers for all four factions: a machine temple, a command bridge, a tomb plain and a war forge. Each pack offers its own; picking a theme never changes your wallpaper unless you ask.
- Settings → Themes: preview for 30 s (nothing permanent is written; it ends by itself, on cancel and if the shell crashes), Apply, return to the previous theme, reset to Mechanicus, recommended wallpapers applied on request, previews of each pack, and the reason a pack cannot be used.
- Your own packs in `~/.local/share/machinespirit/themes/`: JSON and pictures only, validated against a versioned schema (now 2, with a `skin` section that picks a built-in livery per part; schema 1 packs still load). A pack cannot run code.
- `ms-theme packs | preview | preview-end | revert` and `apply --pack ID --save`; the `theme` IPC target. A theme applied while the screen is locked waits for unlock.
- Settings pages: Themes, Animations & effects, Bar & panels, Desktop & widgets, Notifications; Session became Session & controls. Grouped sidebar; search finds individual controls and highlights them.
- New settings: panel opacity, glow strength, density, decoration level, bar modules and their order, weather and network rate on the bar, bar on every screen, widget scan line, effect intensity, frequency and kinds, animation speed, pop-up time and count, urgent messages through quiet mode, log size, hold time for dangerous actions, tap Super for the console. Files from 0.2.0 are read as they are; new keys take their defaults.
- Mechanicus: the control desk unlatches when it opens and its plates take a brief charge; large windows carry brass corner straps and a riveted band; scorched cable smokes after some strikes; steam vents with the sparks on a real overheat; the Cogitator's scanlines thicken under real load; serial plates show a burst of binary now and then; a greeting at start and a line after purging the log.

### Changed

- Colour modes are named `faction`, `guarded` and `follow`. `fixed` and `strict` still work and mean the same as before; `theme.conf` is not rewritten.
- Reduced motion also stops lamp flicker, sparks and the cog; low power still stops everything ambient. Ambient effects take turns: never more than one at a time across the shell.
- Settings: the sidebar status card was dropped (the status line at the bottom says the same); Motion & power moved to Animations & effects.
- The release archive carries the four packs, their wallpapers and the faction faces; it is larger than before (see Install).

### Fixed

- With reduced motion, the console's sector doors stayed shut over the workspace previews.

### Known limitations

- Tested with a virtual GPU (QEMU/KVM, virgl). Physical hardware and NVIDIA are untested.
- None of the three faction faces has Cyrillic; such text is set in IBM Plex.

## 0.2.0 - 2026-11-08

One command now gives a working desktop: `./install.sh --full --yes`, reboot, sign in.

### Added

- Login screen: the `login` component installs and enables SDDM with a MachineSpirit theme (phosphor housing, clock, user and session choice, keyboard layout, error feedback; it needs no shell, matugen or Hyprland and carries its own font). It is part of `--full`, but only when no login manager is present: an existing SDDM or any other login manager is left as it is and the installer says which session to pick (Hyprland, not UWSM). The theme is switched on only after the SDDM greeter has loaded it; otherwise the default theme stays. sddm.service is enabled but not started, so a running session is never interrupted.
- Passwordless autologin, only on request: `--with-autologin` or the answer to a question in an interactive `--full`. An autologin you already have is not overridden.
- Lock screen drawn by the shell (Quickshell session lock with PAM), in the style of the login screen: blurred wallpaper, housing, nixie clock, shake on a wrong passphrase. The lock is reported as held only after the compositor confirms it. If the shell dies while locked, the screen stays locked and the restarted shell takes the lock over. hyprlock stays as the fallback and is chosen with the new `lockBackend` setting (`quickshell` by default). It is used automatically only when the shell is not running and nothing is locked; a second locker is never started on top of a held lock.
- The installer works from a plain text console (no graphical environment) and from a running Hyprland session, where nothing is restarted.

### Changed

- While the screen is locked, `ms-session restart`, `./install.sh` and `ms-update install` refuse to run and change nothing, and the shell stops reloading its files (`ms-session locked` reports the state). A reload or restart under a lock used to end on Hyprland's "lockscreen app died" screen.
- `--full` includes the login component. The boot theme stays a separate choice (`--with-boot`). The boot component still refuses a machine that already has a login manager; `--full --with-boot` installs the boot theme first and the login screen after it.
- An update, from Settings or `./install.sh update`, never touches the boot theme.
- The session supervisor starts the shell again if it crashes (at most five times a minute); `ms-session lock` returns when the lock is confirmed.
- hyprlock was restyled to match.
- Hyprland's "updated to x.y.z" notes window no longer covers the first screen of a new install (`ecosystem:no_update_news`); its donation reminder is left to upstream.
- Uninstall also removes what the login component wrote and disables sddm.service if the installer enabled it.

### Known limitations

- Tested in a QEMU/KVM guest: installs from a text console and from a running Hyprland with reboot and sign-in, an existing SDDM, lightdm, autologin, uninstall and restore, the boot theme with SDDM, lock and unlock with PAM, a wrong passphrase, missing PAM configuration, two outputs, a killed shell while locked, and suspend with the lock held. After resuming, the guest's virtual GPU left the window black (also without MachineSpirit), so the lock screen after suspend was not seen. Physical hardware, NVIDIA, other login managers and the Plymouth splash itself are untested.
- If the shell cannot restart while the screen is locked, Hyprland shows its own recovery screen; follow what it says (`hyprctl --instance 0 eval 'hl.clear_crashed_lockscreen()'` from another console).

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
