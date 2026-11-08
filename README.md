<p align="center"><img src="docs/media/banner.svg" alt="MachineSpirit: phosphor instruments and forged metal" width="100%"></p>
<p align="center"><b>English</b> · <a href="README.ru.md">Русский</a> · <a href="docs/INSTALL.md">Installation & recovery</a> · <a href="docs/SETTINGS.md">Settings</a> · <a href="docs/KEYBINDINGS.md">Keybindings</a></p>

**MachineSpirit** is a desktop shell for Hyprland, built with Quickshell: phosphor screens, Nixie clocks and machined housings, with colours taken from your wallpaper. It is an unofficial fan project in the style of the Warhammer 40,000 Adeptus Mechanicus.

**0.1.0** · Arch Linux / CachyOS · Wayland · [GPL-3.0-only](LICENSE) · Author: [Kukushkasus](https://github.com/Kukushkasus)

Idle usage in the test VM (4 vCPUs): about 2 to 3% CPU and 600 MiB RAM.

<p align="center"><img src="docs/media/showcase.gif" alt="20-second MachineSpirit demo recorded in a VM: desktop, launcher, control panel, wallpaper archive, settings and updates" width="100%"></p>

## Screenshots

![Desktop with the five instruments and a notification](docs/media/desktop.png)

![Settings](docs/media/settings.png)

![Privacy settings](docs/media/privacy.png)

## Features

- Command console with workspace overview, control panel (Sanctum), notification archive and wallpaper browser.
- Five movable desktop instruments: clock, weather, resources, media player and persistent notes.
- Nine searchable settings pages: live window preview, display arrangement with automatic rollback, pointer controls, shortcut recording and updates. Unsaved changes are protected.
- First-launch setup with privacy presets, per-feature network permissions and an optional authenticated proxy. Browser policy changes have their own preview, administrator authorization and restore.
- Wallpaper colours flow through the shell and the components you choose to install. Short, consistent transitions; reduced-motion and low-power modes. A lock screen and an optional Plymouth boot theme.
- **Super+/** opens the searchable shortcut manual, **Super+,** opens Settings, **Super+Alt+W** edits the desktop instruments. The interface is English; keyboard layouts are configurable.

## Requirements

Arch Linux or CachyOS, Hyprland 0.55 or newer with the Lua configuration API (tested with 0.57), Quickshell (tested with 0.3.2), Python 3.11+ and `pacman`. Details are in [Installation and recovery](docs/INSTALL.md#requirements).

## Install

Clone or download this repository, enter its directory and run:

```sh
./install.sh
```

Choose individual components or a full installation. To inspect the changes first:

```sh
./install.sh --full --dry-run
./install.sh --components shell,hyprland,terminal,apps,lock,wallpapers
```

Existing files are backed up, and your own edits are preserved on update. The optional boot component supports GRUB with mkinitcpio and no display manager, and asks before it changes anything. Package installation needs `sudo`, but the installer itself runs as your normal user. AUR is optional. Read [installation and recovery](docs/INSTALL.md) before installing.

## Update

Open **Settings, Updates** or run `ms-update`: it checks for a new release only when you ask, shows what changed and installs with backups. From a Git checkout, run `git pull` and `./install.sh update`. See [updating](docs/INSTALL.md#updating).

## Configuration

Settings live in `~/.config/machinespirit/settings.json` (or the XDG equivalent); the interface and the file describe the same options. Updates keep your layouts, display preferences and notes. Display changes have a 15-second confirmation window with a separate rollback process.

```json
{
  "version": 1,
  "layouts": ["us", "ru"],
  "primaryOutput": "DP-1"
}
```

## Documentation

- [Installation and recovery](docs/INSTALL.md): requirements, components, updating, backups, rollback and the boot component.
- [Settings](docs/SETTINGS.md): the settings file, privacy, proxy, browser policies and updates.
- [Keybindings](docs/KEYBINDINGS.md): every shortcut, generated from the live catalog.
- [Desktop instruments](docs/desktop-widgets.md): arranging the widgets.
- [Contributing](CONTRIBUTING.md), [changelog](CHANGELOG.md) and [third-party credits](THIRD-PARTY.md).

## Inspiration and credits

- [end-4](https://github.com/end-4/dots-hyprland) and [end4-pC](https://github.com/pctrade/end4-pC): desktop workflow, shortcuts and Super-tap handling.
- [DMS / DUX](https://github.com/duxlabs-dev/dux-shell): early panel and animation references.
- [Noctalia](https://github.com/noctalia-dev/noctalia-shell): settings organization and navigation.
- [Caelestia](https://github.com/caelestia-dots/caelestia): installation, configuration and clock typography references.

Built with Hyprland, Quickshell and Matugen. Warhammer 40,000 and Adeptus Mechanicus belong to Games Workshop; this project is not affiliated with it.

## License

Copyright (c) 2026 Kukushkasus. [GPL-3.0-only](LICENSE). Third-party credits and font licenses: [THIRD-PARTY.md](THIRD-PARTY.md).

Weather may contact wttr.in and infer location from IP; media artwork lookup may contact iTunes; wallpaper providers are contacted when used; update checks contact GitHub only when you ask. See [settings and network behaviour](docs/SETTINGS.md#first-launch-and-privacy).

<p align="center"><img src="docs/media/seal.svg" width="90" alt="Original purity seal"><br><sub>Preserve the user's work. Keep the signal clear.</sub></p>
