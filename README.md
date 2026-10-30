<p align="center"><img src="docs/media/banner.svg" alt="MachineSpirit: phosphor instruments and forged metal" width="100%"></p>
<p align="center"><b>English</b> · <a href="README.ru.md">Русский</a> · <a href="docs/INSTALL.md">Installation & recovery</a> · <a href="docs/SETTINGS.md">Settings</a> · <a href="docs/KEYBINDINGS.md">Keybindings</a></p>

> **THE INSTRUMENTS AWAKEN.**
> A Hyprland desktop with a Quickshell interface: phosphor screens, Nixie clocks, machined housings and a wallpaper-driven palette. Your desktop is an instrument panel, and every control should do something useful.

**0.1.0-beta.1** · Arch Linux / CachyOS · Wayland · [MIT](LICENSE)

Author: [Kukushkasus](https://github.com/Kukushkasus).

<p align="center"><img src="docs/media/desktop.png" alt="Real MachineSpirit desktop running in the test VM" width="100%"></p>

### Inspect the instruments

| The control deck | Your own configuration |
|---|---|
| ![Panels recorded in the VM](docs/media/panels.gif) | ![Settings recorded in the VM](docs/media/settings.gif) |

![Desktop instruments recorded in the VM](docs/media/widgets.gif)

- A command console, workspace overview, control panel, notification archive and wallpaper browser.
- Five movable instruments: clock, weather, resources, media and persistent notes.
- English by default. Add keyboard layouts, select a primary output and configure display modes in Settings.
- **Super+/** opens the searchable shortcut manual. **Super+,** opens Settings. **Super+Alt+W** edits desktop instruments.
- Wallpaper colours flow through the shell and the components you choose to install. Reduced motion and low-power modes are available.
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

### Provenance of the machine

- **Warhammer 40,000 / Adeptus Mechanicus** inspired the industrial ritual, phosphor instrumentation and technical marginalia. This is an unofficial fan project, not affiliated with Games Workshop. The bundled wallpaper and README graphics are original.
- **[end-4/dots-hyprland](https://github.com/end-4/dots-hyprland)** informed familiar desktop interactions, shortcut conventions and the separation of user configuration.
- **[DankMaterialShell / DUX](https://github.com/duxlabs-dev/dux-shell)** was an early reference for tonal panel surfaces and smooth transitions. MachineSpirit subsequently developed its own instrument housings and controls.
- **[Caelestia](https://github.com/caelestia-dots/caelestia)** and the installers above informed component selection, dependency checks and recovery design.
- **[Hyprland](https://hypr.land/)** and **[Quickshell](https://quickshell.org/)** provide the compositor and shell framework; **[Matugen](https://github.com/InioX/matugen)** provides palette generation.

Inspiration is distinct from third-party code and assets; licensing details are in [THIRD-PARTY.md](THIRD-PARTY.md).

### The inspection ledger

[Verification results and limitations](docs/VERIFICATION.md) list what was actually tested. Beta does not mean universal hardware certification. Bluetooth hardware, physical multi-monitor hotplug, DDC and NVIDIA require testing on real devices.

Weather may contact wttr.in and infer location from IP; media artwork lookup may contact iTunes. Wallpaper providers are contacted when used. See [settings and network behaviour](docs/SETTINGS.md).

<p align="center"><img src="docs/media/seal.svg" width="90" alt="Original purity seal"><br><sub>Preserve the user's work. Keep the signal clear.</sub></p>
