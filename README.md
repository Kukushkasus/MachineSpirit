<p align="center"><img src="docs/media/banner.svg" alt="MachineSpirit: phosphor instruments and forged metal" width="100%"></p>
<p align="center"><b>English</b> · <a href="README.ru.md">Русский</a> · <a href="docs/INSTALL.md">Installation & recovery</a> · <a href="docs/SETTINGS.md">Settings</a> · <a href="docs/KEYBINDINGS.md">Keybindings</a></p>

> **THE INSTRUMENTS AWAKEN.**
> A Hyprland desktop with a Quickshell interface: phosphor screens, Nixie clocks, machined housings and a wallpaper-driven palette. Your desktop is an instrument panel, and every control should do something useful.

**0.1.0-beta.1** · Arch Linux / CachyOS · Wayland · [GPL-3.0-only](LICENSE)

Author: [Kukushkasus](https://github.com/Kukushkasus).

Idle usage: **~2–3% CPU on average and ~600 MiB RAM** in the test VM (4 vCPUs).

<p align="center"><img src="docs/media/showcase.gif" alt="18-second MachineSpirit showcase recorded in a VM: launcher, Sanctum, panels, wallpapers, settings and Rite of Departure" width="100%"></p>

### Inspect the instruments

![Settings running in the VM](docs/media/settings.png)

- A command console, workspace overview, control panel, notification archive and wallpaper browser.
- Five movable instruments: clock, weather, resources, media and persistent notes.
- Eight searchable settings sections, live window preview, three appearance presets, pointer controls and shortcut recording. Drafts survive navigation; unsaved changes are protected.
- English by default. Add keyboard layouts, select a primary output and configure display modes in Settings.
- **Super+/** opens the searchable shortcut manual. **Super+,** opens Settings. **Super+Alt+W** edits desktop instruments.

First-launch setup offers privacy presets, city-based weather, per-feature network permissions and authenticated proxy routing. Browser policy changes have their own preview, administrator authorization and restore action. Local shell functions remain available offline. See [privacy settings and limitations](docs/SETTINGS.md#first-launch-and-privacy).

![Privacy setup in the VM](docs/media/privacy.png)

- Wallpaper colours flow through the shell and the components you choose to install. Short, consistent transitions connect panels and controls. Reduced motion and low-power modes are available.
- A lock screen and an optional Plymouth boot theme made for this desktop.

### Initiate the installation

Clone or download this repository, enter its directory, then run:

```sh
./install.sh
```

Choose individual components or a full installation. Inspect the changes first if preferred:

```sh
./install.sh --full --dry-run
./install.sh --components shell,hyprland,terminal,apps,lock,wallpapers
```

**Read [installation and recovery](docs/INSTALL.md) before installing.** Existing files are backed up. Updates preserve detected user edits. The optional boot component currently supports GRUB + mkinitcpio without an existing display manager; it stops on unsupported configurations. Package installation requires sudo, but the installer itself runs as your normal user. AUR is optional.

### Keep your own rites

Configuration lives in `~/.config/machinespirit/settings.json`, or the corresponding XDG directory. The UI and the file describe the same settings. Updates preserve layouts, display preferences and notes. Display changes have a 15-second confirmation window with a separate rollback process.

```json
{
  "version": 1,
  "layouts": ["us", "ru"],
  "primaryOutput": "DP-1"
}
```

See [settings](docs/SETTINGS.md), [shortcut reference](docs/KEYBINDINGS.md) and [desktop widgets](docs/desktop-widgets.md).

### Inspiration

- [end-4](https://github.com/end-4/dots-hyprland) and [end4-pC](https://github.com/pctrade/end4-pC): desktop workflow, shortcuts and Super-tap handling.
- [DMS / DUX](https://github.com/duxlabs-dev/dux-shell): early panel and animation references.
- [Noctalia](https://github.com/noctalia-dev/noctalia-shell): settings organization and navigation.
- [Caelestia](https://github.com/caelestia-dots/caelestia): installation, configuration and clock typography references.
- Warhammer 40,000 / Adeptus Mechanicus: visual inspiration. Unofficial fan project, not affiliated with Games Workshop.

Built with Hyprland, Quickshell and Matugen.

### License

Copyright (c) 2026 Kukushkasus. [GPL-3.0-only](LICENSE). Third-party credits and font licenses: [THIRD-PARTY.md](THIRD-PARTY.md).

Weather may contact wttr.in and infer location from IP; media artwork lookup may contact iTunes. Wallpaper providers are contacted when used. See [settings and network behaviour](docs/SETTINGS.md).

<p align="center"><img src="docs/media/seal.svg" width="90" alt="Original purity seal"><br><sub>Preserve the user's work. Keep the signal clear.</sub></p>
