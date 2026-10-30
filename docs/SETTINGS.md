# User settings

Open **Super+,** or the Settings button in the control panel. **Super+/** opens the shortcut manual. Normal configuration does not require a terminal.

Settings are stored in `$XDG_CONFIG_HOME/machinespirit/settings.json` (default `~/.config/machinespirit/settings.json`). The file is versioned JSON. Missing supported fields receive defaults; unsupported versions and invalid values are rejected. After manual edits, run `ms-settings generate` and reload Hyprland. The settings UI watches the file.

| Field | Default | Meaning |
|---|---|---|
| version | 1 | File format |
| layouts | `["us"]` | 1–4 XKB keyboard layout names |
| layoutSwitch | `grp:alt_shift_toggle` | XKB switching option |
| primaryOutput | empty | Fixed preferred output, e.g. `DP-1`; empty uses first available |
| monitors | empty | Use compositor defaults until explicitly configured |
| reducedMotion | false | Reduce interface and compositor animations |
| lowPower | false | Reduce shell effects and disable compositor blur/animations |
| blur | true | Compositor blur outside low-power mode |
| lockSeconds | 600 | Idle lock timeout |
| screenOffSeconds | 900 | Screen-off timeout, at least lockSeconds |
| bindings | `{}` | Original combination → replacement; empty string disables |

The English interface is not translated in this beta. Keyboard layouts are independent of interface language. User overrides in `hypr/local.lua` remain outside the shipped configuration; settings-managed values are applied after the standard look configuration.

## Displays

Select an output and its advertised mode, scale, rotation and position. Positions use compositor logical coordinates, such as `0x0`, `1920x0` or `-1920x0`; scale changes the logical size. A selected primary output controls placement of major panels and the startup overlay. The bar stays available on each screen. Individually placed desktop widgets retain their own screen assignments.

If the primary output disappears, panels fall back to the first available output. Its saved preference is retained for reconnection. Display changes through Settings require confirmation within 15 seconds; a separate watchdog restores the previous settings if the UI closes or crashes. Do not bypass this safeguard by directly editing monitor settings unless you have another way into the machine.

Example:

```json
{
  "version": 1,
  "layouts": ["us", "ru"],
  "primaryOutput": "DP-1",
  "monitors": [
    {"output": "DP-1", "mode": "2560x1440@144", "position": "0x0", "scale": 1, "transform": 0, "disabled": false},
    {"output": "HDMI-A-1", "mode": "1920x1080@60", "position": "2560x0", "scale": 1, "transform": 0, "disabled": false}
  ]
}
```

Use your own advertised modes, not these example values.

## Other persisted data

Widget positions and notes live in `$XDG_STATE_HOME/machinespirit/desktop-widgets.json`. Do not delete this file to update the shell. Wallpaper API keys live in `$XDG_CONFIG_HOME/machinespirit/keys.conf`, mode 0600; never commit that file.

Theme policy remains in `theme.conf` next to settings. `ms-theme apply IMAGE` applies a wallpaper and generates colours only for installed components. The wallpaper archive can do this from the UI.

## Network behaviour

Weather requests go to wttr.in and default to IP-based location; `MS_WEATHER_LOCATION` overrides it. Artwork fallback may send artist/title to iTunes; `MS_COVER_LOOKUP=0` disables it. Wallpaper searches contact the chosen provider. Notifications and notes are local. The repository includes no API credentials.
