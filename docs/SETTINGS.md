# User settings

Open with **Super+,** or the Settings button in the control panel. **Super+/** opens the shortcut manual.

The sidebar has four groups:

- **Look**: Appearance, Themes, Animations & effects
- **Shell**: Bar & panels, Desktop & widgets, Notifications
- **System**: Displays, Keyboard, Pointer, Session & controls, Shortcuts
- **Data**: Privacy, Browsers, Updates

Search finds a control by name, opens its page and highlights it. Appearance has a live geometry preview and Balanced, Compact and Square presets. Theme packs are in [THEMES.md](THEMES.md).

Changes stay a draft until **Apply changes**. **Discard** drops them, **Reset page** puts the page back to defaults, and closing with unsaved changes asks what to do.

Settings are stored in `$XDG_CONFIG_HOME/machinespirit/settings.json` (default `~/.config/machinespirit/settings.json`). It's versioned JSON: missing fields get defaults, unknown versions and bad values are rejected. If you edit it by hand, run `ms-settings generate` and reload Hyprland; the settings window picks up changes on its own.

| Field | Default | Meaning |
|---|---|---|
| version | 1 | File format |
| layouts | `["us"]` | 1–4 XKB keyboard layout names |
| layoutSwitch | `grp:alt_shift_toggle` | XKB switching option |
| primaryOutput | empty | Fixed preferred output, e.g. `DP-1`; empty uses first available |
| monitors | empty | Use compositor defaults until explicitly configured |
| reducedMotion | false | No decorative movement, flicker or flashes; instant transitions in the shell and the compositor |
| lowPower | false | Reduce shell effects and disable compositor blur, shadows and animations |
| blur | true | Compositor blur outside low-power mode |
| rounding / gapsIn / gapsOut / borderSize | 14 / 6 / 12 / 2 | Window corner radius, inner/outer gaps and border width in pixels |
| shadows / dimInactive / dimStrength | true / true / 0.10 | Window shadows and inactive-window dimming (0–0.5) |
| sensitivity / accelProfile | 0 / adaptive | Pointer sensitivity (−1 to 1), adaptive or flat acceleration |
| naturalScroll / tapToClick | true / true | Touchpad scrolling direction and tap to click |
| leftHanded / followMouse | false / true | Swap pointer buttons; focus windows under the pointer |
| repeatRate / repeatDelay | 25 / 600 | Key repeat rate per second and initial delay in milliseconds |
| lockSeconds | 600 | Idle lock timeout |
| screenOffSeconds | 900 | Screen-off timeout, at least lockSeconds |
| lockBackend | quickshell | Lock screen: `quickshell` (the shell's own) or `hyprlock`. The shell falls back to hyprlock only when it is not running, never on top of a lock that is held |
| bindings | `{}` | Original combination → replacement; empty string disables |
| panelOpacity / glowStrength | 1 / 1 | Opacity of the panels' glass (0.6–1) and strength of the phosphor halo (0–1.5) |
| density | comfortable | `compact` tightens the bar's groups and the control desk; controls keep their size |
| ornaments | full | `full`, `reduced` (no seals, heraldry or console guardians) or `off` (also no fittings between the bar's mounts) |
| barLeft / barRight | `["clock","instruments","caption"]` / `["media","tray"]` | Bar modules in order; a module left out is hidden. The cog and the controls are fixed |
| barWeather / barNetRate / barAllScreens | true / true / true | Weather beside the clock, the network rate in figures, the bar on every screen (or only the panel screen) |
| widgetScan | true | The faint sweep across desktop instruments |
| fxLevel / fxFrequency | 2 / 1 | Ambient effects: 0 off, 1 subtle, 2 normal, 3 lively; how often they come (0.5–2) |
| fxDischarge / fxScreens / fxParticles / fxMessages | true | The kinds of ambient effect: discharges at the bar, life on the screens, particles, atmospheric messages and signs |
| animSpeed | 1 | Speed of transitions (0.5–2); the theme pack sets their character |
| toastSeconds / toastMax | 6 / 4 | How long a pop-up stays when the application does not say, and how many show at once |
| urgentThroughQuiet / historyLimit | true / 100 | Critical messages still pop up in quiet mode; how many messages the log keeps (10–300) |
| holdMs / superTap | 800 / true | How long Reboot, Shut down and Log out are held (400–2500 ms); tapping Super opens the console |
| cursorMode / cursorSize / cursorTheme | faction / 24 / empty | The pointer: `faction` (the active theme's MachineSpirit cursor), `system` (the cursor you had before MachineSpirit set one) or `custom` (the installed theme named in `cursorTheme`); size 24, 32, 40 or 48. Applied by `ms-cursor`; see [Theme packs](THEMES.md#cursors) |
| privacy | see below | Network permissions and proxy; edited on the Privacy page |

The `privacy` object:

| Field | Default | Meaning |
|---|---|---|
| mode | `custom` | `normal`, `recommended` or `local` (the presets), or `custom` |
| weather, publicIp, coverSearch, remoteArt, wallpapers | `auto` | `auto`, `manual` (on request) or `off` for each network feature |
| updates | `manual` | The same three values for update checks |
| weatherMode / city | `ip` / empty | Locate weather by exit IP, or use `city` |
| proxy | disabled | `enabled`, `scheme` (`http`, `https`, `socks5`), `host`, `port`, `username` and `shell` (route shell requests through it); the password is stored separately |

The interface is English only for now; keyboard layouts don't depend on it. Your own overrides in `hypr/local.lua` stay outside the shipped config, and values from Settings are applied after the standard look config.

## Displays

Pick an output and set its mode, scale, rotation and position. Positions are in logical coordinates (`0x0`, `1920x0`, `-1920x0`), and scale changes the logical size. The primary output gets the big panels and the startup overlay; the bar is on every screen, and desktop widgets keep their own screens.

If the primary output disappears, panels move to the first available one and go back when it's reconnected. Display changes from Settings have to be confirmed within 15 seconds, otherwise a watchdog puts the old settings back, even if the window closes or crashes. Editing monitor settings by hand skips that safety net, so have another way into the machine.

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

## Shortcuts

Pick an action, press **Record keys** and then the combination. You can also type a Hyprland combination, disable an action or restore its default. Esc cancels. Compositor shortcuts are paused while recording. Conflicts are checked before saving, and a broken config doesn't overwrite your saved settings. Recording knows Latin letters, numbers, F-keys and the usual navigation keys; type anything else by hand.

## Cursor

`ms-cursor apply` sets the pointer the settings ask for: through `hyprctl setcursor` for the running session, `cursor.lua` (next to `settings.json`) for the next login, the GNOME `cursor-theme` and `cursor-size` keys for GTK, and `~/.icons/default/index.theme` for X11 applications, but only when that file is missing or was written by MachineSpirit. The cursor in use before the first change is recorded in `~/.local/state/machinespirit/cursor-origin.json`; `system` mode and uninstalling return to it. `ms-cursor status` shows what is set. Applications started before a change may keep the previous pointer until they are restarted.

The themes are drawn on first use with `rsvg-convert` (librsvg, installed with the shell) and, for Hyprland's own scalable format, `hyprcursor-util` (part of Hyprland's `hyprcursor` package). Without `hyprcursor-util` only the XCursor form is made, which Hyprland also reads; without `rsvg-convert` nothing is drawn and the current pointer stays. A cursor set by hand in `hypr/local.lua` takes precedence at login; choose **System** or **Custom** so switching themes does not change it for the running session.

## Other persisted data

Widget positions and notes live in `$XDG_STATE_HOME/machinespirit/desktop-widgets.json`. Do not delete this file to update the shell. Wallpaper API keys live in `$XDG_CONFIG_HOME/machinespirit/keys.conf`, mode 0600; never commit that file.

Theme policy remains in `theme.conf` next to settings: the theme pack (`pack`) and the colour mode (`mode`). `ms-theme apply IMAGE` applies a wallpaper and generates colours only for installed components; the pack and mode are kept. The wallpaper archive can do this from the UI. See [THEMES.md](THEMES.md).

## First launch and privacy

The first launch opens a six-step setup: privacy preset, network and weather, browsers, appearance, keyboard and a review. The shell makes no background requests until you press **Finish setup**. Existing installs are offered the setup once, without replacing saved preferences. **Skip setup** finishes right away with safe defaults (weather and public IP lookups off). Closing it just postpones it; **Privacy → Run setup again** brings it back.

**Normal** turns on the optional networking. **Recommended** keeps weather and wallpapers, asks for a city, and makes public IP and cover lookups manual. **Local only** blocks all of the shell's outside requests, including remote notification images, artwork and wallpaper thumbnails; local widgets, playback controls, notes and local wallpapers still work, and cached weather is marked as saved. These modes cover the shell only, not the whole computer.

Each network feature can be on, manual or off. Manual weather, IP and cover lookups are in Privacy, online wallpaper search is in the wallpaper archive. Who gets contacted: wttr.in for weather, ipify for public IP, iTunes for covers (artist and title), the original host for remote artwork and notification images, the chosen provider for wallpapers, and GitHub for updates, only when you press refresh. The shell doesn't upload notifications, and their text is shown as plain text, not markup.

Weather uses either a city you enter or your exit IP; with a proxy that's the proxy's location. A city avoids IP geolocation but doesn't hide your IP. `MS_COVER_LOOKUP=0` still turns cover lookup off completely, and the city setting replaces `MS_WEATHER_LOCATION` after migration.

### Proxy

Set your own HTTP, HTTPS or SOCKS5 proxy, with an optional username and password. Apply the connection, then choose shell routing and browser routing separately. **Test saved proxy** asks ipify through the saved proxy and makes no direct request to compare.

GOST v3 runs as part of the session and forwards a local HTTP listener on port 17879 through your proxy. If the proxy fails or is off, nothing falls back to a direct connection. Browsers routed through it keep pointing at that listener until you restore them, so turning the proxy off can leave them offline. The listener is only local, it's not a firewall or multi-user isolation. Your proxy provider can still see connection metadata; this isn't an anonymity tool.

The password is stored separately in `~/.config/machinespirit/proxy-secret.json` (mode 0600), the generated GOST config in the private runtime dir. Credentials never go into command arguments, diagnostics or release archives. Changing permissions cancels shell downloads in progress. Remote images go through the same permission checks and only raster formats are accepted.

### Browser policies

The Browsers page works with native Linux installs of Firefox, Chrome, Chromium, LibreWolf and Zen. Sandboxed packages and other unusual layouts are left alone. Policies that already block something are shown separately from your switches. A written policy file doesn't prove the browser applies it, so check.

Pick the controls, look at the exact policy preview and apply with admin rights. Policies apply to all profiles of that browser. Setup only prepares the choices; a browser changes only when you press its own Apply. Restart the browser yourself and check `about:policies` or `chrome://policy`; no tabs get closed.

Controls: usage telemetry, Firefox studies, crash uploads, search suggestions, speculative loading and proxy routing. Chrome/Chromium have usage and crash reporting under one metrics policy. LibreWolf and Zen already strip telemetry, their own policies are kept. Proxy routing also blocks direct DNS, QUIC and WebRTC where supported, which may break calls. It's not a system-wide kill switch.

Admin policies that conflict are not overwritten. **Restore previous** removes only MachineSpirit's own unchanged values and puts the originals back; outside changes are shown as conflicts. Updates, certificate checks, safe browsing, profiles and saved passwords are never turned off or deleted. Browser package upgrades can replace policy files, so refresh the status after updating.

The installer puts a root-owned helper at `/usr/local/libexec/ms-browser-policy` with a Polkit action. No user-writable script runs as root on Apply, and the helper accepts only fixed browser IDs and a fixed list of on/off controls. Uninstall restores browser values before removing the helper, and stops on conflicts instead of overwriting later edits.

## Updates

The last page shows the installed version and whether a newer release exists. The refresh button asks GitHub (permission "Update checks" under Privacy, default *On request*; blocked in Local only mode, and routed through your proxy if you route shell requests through it). **Update dots** opens a terminal that checks the downloaded archive against the release's `SHA256SUMS`, shows what is new and asks before installing (details and limits in [Installation and recovery](INSTALL.md#updating)). The installed version is recorded in `~/.local/share/machinespirit/VERSION`; the last answer is cached in `~/.local/state/machinespirit/update.json`.
