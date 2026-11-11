<p align="center"><img src="docs/media/banner.svg" alt="MachineSpirit: phosphor instruments and forged metal" width="100%"></p>
<p align="center"><b>English</b> · <a href="README.ru.md">Русский</a> · <a href="docs/INSTALL.md">Installation & recovery</a> · <a href="docs/SETTINGS.md">Settings</a> · <a href="docs/KEYBINDINGS.md">Keybindings</a></p>

<details>
<summary><b>I'm not reading all that. Just give me the install command.</b></summary>

Fine. On Arch Linux or CachyOS, as your normal user (not root, not through `sudo`):

```bash
git clone https://github.com/Kukushkasus/MachineSpirit.git
cd MachineSpirit
./install.sh --full --yes
```

Then reboot and sign in on the login screen with the Hyprland session.

- It works from a plain text console and from a Hyprland session you already run. Nothing that is running gets restarted.
- You need `git`. The installer asks for `sudo` and installs the rest, including the SDDM login screen if you have no login manager yet.
- Your existing files are backed up first. A login manager you already use is left alone.
- Autologin is off by default. The GRUB/Plymouth boot theme is a separate option.
- Details, options and recovery: [Installation and recovery](docs/INSTALL.md).

</details>

**MachineSpirit** is a desktop shell for Hyprland, built with Quickshell: phosphor screens, Nixie clocks and machined housings, with colours taken from your wallpaper. Four faction liveries redraw the whole shell (Adeptus Mechanicus, Ultramarines, Necrons and Khorne) while every control stays where it is. It is an unofficial fan project in the style of Warhammer 40,000.

**0.5.0 · Road to 1.0 (pre-release)** · Arch Linux / CachyOS · Wayland · [GPL-3.0-only](LICENSE) · Author: [Kukushkasus](https://github.com/Kukushkasus)

- Bar, command console with workspace overview, control desk (Sanctum), popups, notification archive, wallpaper archive and five movable desktop instruments.
- Settings Center with fourteen searchable pages: appearance, themes, bar, widgets, effects, notifications, displays, input, session, shortcuts, privacy, browsers and updates.
- Four theme packs with their own wallpapers, display faces and motion; a safe preview, apply and revert; your own packs as plain data.
- Login, lock and boot in the same style; reduced-motion and low-power modes; installs and updates with backups.

## Showcase: Adeptus Mechanicus

<p align="center"><img src="docs/media/showcase.gif?v=0.5.0" alt="MachineSpirit with the Adeptus Mechanicus theme, recorded in a VM: SDDM login, desktop with bar and instruments, command console, Sanctum, network, media and calendar popups, the wallpaper archive, Settings and the power menu" width="100%"></p>

<p align="center"><sub>Recorded in a QEMU/KVM guest. <a href="docs/media/showcase.mp4">Full-quality video (MP4)</a></sub></p>

## Faction themes

One shell, four liveries. A theme changes the bar's silhouette, the housings and their glass, cards and titles, keys and gauges, workspace marks, popups, toasts, the power wheel, the lock screen, the display face and how things move. The layout, the click areas and the readings stay the same.

| Adeptus Mechanicus | Ultramarines |
|---|---|
| ![Adeptus Mechanicus: the machine temple wallpaper, clamped bar plates with cables, CRT glass and Sanctum](docs/media/factions/mechanicus.jpg) | ![Ultramarines: the command bridge wallpaper, a continuous armour band, gold-trimmed plates and Sanctum](docs/media/factions/ultramarines.jpg) |
| **Necrons** | **Chaos: Khorne** |
| ![Necrons: the tomb plain wallpaper, floating bar shards, monolith housings and Sanctum](docs/media/factions/necrons.jpg) | ![Khorne: the war forge wallpaper, toothed iron bar slabs and chains, forge glass and Sanctum](docs/media/factions/khorne.jpg) |

<p align="center"><img src="docs/media/themes.gif?v=0.5.0" alt="Switching between the four faction themes live" width="100%"></p>

Each pack brings its own 3840×2160 wallpaper (a machine temple, a command bridge, a tomb plain and a war forge), rendered in Blender from the scene scripts in [`tools/wallpapers/`](tools/wallpapers). Choosing a theme never changes your wallpaper unless you ask. See [Theme packs](docs/THEMES.md).

## Settings Center and theme packs

![Settings: the Themes page with previews of the four packs](docs/media/settings-themes.jpg)

- **Themes:** preview a pack for 30 seconds without saving anything, then keep it or let it run out; return to the previous theme at any time. Colour modes: keep the faction's palette, guard it against the wallpaper, or follow the wallpaper.
- **Your own packs:** a folder in `~/.local/share/machinespirit/themes/` with a `theme.json` and pictures. A pack picks built-in liveries by name and tunes colours, words and motion; it cannot run code.
- **Appearance and effects:** panel opacity, glow, density, decoration level, effect intensity and frequency, animation speed, reduced motion and low power.
- **Bar, widgets, notifications, session:** which bar modules appear and in what order, widget options, pop-up time and count, quiet mode, hold time for dangerous actions.
- **Search** finds a single setting and takes you to it. Display changes have a 15-second confirmation with automatic rollback.

## Install and compatibility

The release archive is about 6 MiB (four 4K wallpapers and three display faces included).

Arch Linux or CachyOS, Hyprland 0.55 or newer with the Lua configuration API (tested with 0.57), Quickshell (tested with 0.3.2), Python 3.11+ and `pacman`. Details are in [Installation and recovery](docs/INSTALL.md#requirements).

The quickest way is the box at the top: `./install.sh --full --yes`, reboot, sign in. The same command works from a text console and from a Hyprland session that is already running. It installs the packages, the shell, the Hyprland configuration, the lock screen and, when no login manager is present, the SDDM login screen.

## Advanced installation

Choose individual components or a full installation. To inspect the changes first:

```sh
./install.sh --full --dry-run
./install.sh --components shell,hyprland,terminal,apps,lock,wallpapers
```

Existing files are backed up, and your own edits are preserved on update. The optional boot component supports GRUB with mkinitcpio and no display manager, and asks before it changes anything. Package installation needs `sudo`, but the installer itself runs as your normal user. AUR is optional. Options such as `--with-autologin`, `--with-boot` and `--no-packages`, the rules for an existing login manager and recovery are in [Installation and recovery](docs/INSTALL.md).

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
- [Theme packs](docs/THEMES.md): the four factions, previews, colour modes and making your own pack.
- [Keybindings](docs/KEYBINDINGS.md): every shortcut, generated from the live catalog.
- [Desktop instruments](docs/desktop-widgets.md): arranging the widgets.
- [Contributing](CONTRIBUTING.md), [changelog](CHANGELOG.md) and [third-party credits](THIRD-PARTY.md).

## Known limitations

- Tested in a QEMU/KVM guest with a virtual GPU. Physical hardware, NVIDIA and multi-GPU setups are untested.
- The wallpapers are 3D scenes rendered from code, not hand-painted art.
- The faction display faces have no Cyrillic; such text is set in IBM Plex. The interface itself is English.
- This is a pre-release on the way to 1.0: expect changes to the theme pack format before 1.0.

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
