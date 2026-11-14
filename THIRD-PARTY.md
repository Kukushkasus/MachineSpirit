# Third-party credits

| Component | License / source | Role |
|---|---|---|
| Hyprland | [BSD-3-Clause](https://github.com/hyprwm/Hyprland) | Compositor |
| Quickshell | [LGPL-3.0](https://github.com/quickshell-mirror/quickshell) | Shell framework |
| Matugen | [GPL-2.0](https://github.com/InioX/matugen) | External palette generator |
| GOST v3 | [MIT](https://github.com/go-gost/gost) | Optional local proxy forwarder; system package, not bundled |
| IBM Plex Sans / Condensed | OFL-1.1, `assets/fonts/OFL-IBMPlex.txt` | Bundled fonts; the SDDM login theme carries its own copy with the licence in `assets/sddm/machinespirit/fonts/` |
| UnifrakturCook | OFL-1.1, `assets/fonts/OFL-UnifrakturCook.txt` | Bundled display font |
| Cinzel | OFL-1.1, `quickshell/assets/fonts/OFL-Cinzel.txt` | Ultramarines display face, loaded by the shell from its own folder |
| Michroma | OFL-1.1, `quickshell/assets/fonts/OFL-Michroma.txt` | Necrons display face, loaded by the shell from its own folder |
| Grenze Gotisch | OFL-1.1, `quickshell/assets/fonts/OFL-GrenzeGotisch.txt` | Khorne display face, loaded by the shell from its own folder |
| JetBrainsMono Nerd Font | OFL-1.1; system package | Monospace glyphs |
| Material Symbols | Apache-2.0; system package | UI icons |
| end-4/dots-hyprland, end-4 and contributors | [GPL-3.0](https://github.com/end-4/dots-hyprland/blob/main/LICENSE) | Super-tap handling adapted in `hypr/binds.lua` and `quickshell/shell.qml`; desktop reference. |
| pctrade/end4-pC, pctrade and contributors | [GPL-3.0](https://github.com/pctrade/end4-pC/blob/main/LICENSE) | Desktop and visual reference. |
| DMS / DUX | [Upstream](https://github.com/duxlabs-dev/dux-shell) | Early visual and installer reference; not vendored |
| Caelestia | [Upstream](https://github.com/caelestia-dots/caelestia) | Component/install reference; not vendored |
| Noctalia | [Upstream](https://github.com/noctalia-dev/noctalia-shell) | Settings organization and navigation reference; not vendored |


The four faction wallpapers in `quickshell/themes/*/wallpapers/` are original MachineSpirit work under the project licence, rendered in Blender from scenes built in code (no outside models, textures or artwork). The four cursor themes are drawn by `tools/make_cursors.py` from shapes defined in that file, under the project licence; no third-party cursor artwork is used. Bundled fonts retain their OFL copyright and license notices in `assets/fonts/` and `quickshell/assets/fonts/`. External dependencies retain their own licenses. Wallpapers downloaded from external providers are subject to their original terms.
