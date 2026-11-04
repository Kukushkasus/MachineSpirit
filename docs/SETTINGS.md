# User settings

Open **Super+,** or the Settings button in the control panel. **Super+/** opens the shortcut manual. Use the sidebar or search to find controls. Appearance includes a live geometry preview and Balanced, Compact and Square presets. Changes stay in a draft until **Apply changes**; **Discard** restores saved values, and **Defaults** resets the current section. Closing with a modified draft asks whether to keep editing or discard it.

Settings are stored in `$XDG_CONFIG_HOME/machinespirit/settings.json` (default `~/.config/machinespirit/settings.json`). The file is versioned JSON. Missing supported fields receive defaults; unsupported versions and invalid values are rejected. After manual edits, run `ms-settings generate` and reload Hyprland. The settings UI watches the file.

| Field | Default | Meaning |
|---|---|---|
| version | 1 | File format |
| layouts | `["us"]` | 1–4 XKB keyboard layout names |
| layoutSwitch | `grp:alt_shift_toggle` | XKB switching option |
| primaryOutput | empty | Fixed preferred output, e.g. `DP-1`; empty uses first available |
| monitors | empty | Use compositor defaults until explicitly configured |
| reducedMotion | false | Reduce interface and compositor animations |
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

## Shortcuts

Select an action and choose **Record keys**, then press a combination. You can also type the Hyprland combination directly, disable an action, or restore its original binding. Escape cancels recording. Compositor shortcuts are inhibited while the recorder dialog is open. Conflicts are checked before saving; an invalid configuration leaves the saved settings intact. Recording recognizes Latin letters, numbers, function keys and common navigation keys; use manual entry for other key names.

## Other persisted data

Widget positions and notes live in `$XDG_STATE_HOME/machinespirit/desktop-widgets.json`. Do not delete this file to update the shell. Wallpaper API keys live in `$XDG_CONFIG_HOME/machinespirit/keys.conf`, mode 0600; never commit that file.

Theme policy remains in `theme.conf` next to settings. `ms-theme apply IMAGE` applies a wallpaper and generates colours only for installed components. The wallpaper archive can do this from the UI.

## First launch and privacy

The first launch opens a six-step setup flow: privacy preset, network/weather, browsers, appearance, keyboard and review. Background shell requests remain paused until **Finish setup**. Existing installations are offered setup once without replacing their saved preferences. Closing setup postpones it; **Privacy → Run setup again** opens it later.

**Normal** enables optional shell networking. **Recommended** keeps weather and wallpapers, asks for a city, and makes public-IP and track-cover lookups manual. **Local only** blocks the shell's external requests, including remote notification images, artwork and wallpaper thumbnails. Local instruments, playback controls, notes and local wallpapers remain available. Cached weather is marked saved. These modes do not isolate the whole computer.

Each network feature can be allowed, manual or blocked. Manual weather, public-IP and cover requests are available in Privacy. Online wallpaper searches are initiated in the wallpaper archive. Weather uses wttr.in; public IP uses ipify; cover search sends artist/title to iTunes. Remote artwork and notification images contact their originating hosts. Wallpaper requests contact the selected provider. Notifications are not uploaded by the shell. Text metadata is displayed as plain text rather than executable image markup.

Weather can use a city entered manually or the connection's exit IP. With a proxy, IP location is the proxy's location. A city avoids IP-based geolocation but does not hide the connection's IP. `MS_COVER_LOOKUP=0` remains a hard opt-out; the city setting replaces `MS_WEATHER_LOCATION` after migration.

### Proxy

Configure your own HTTP, HTTPS or SOCKS5 proxy, with optional username/password. Apply the connection settings, then select shell routing and browser routing independently. **Test saved proxy** explicitly contacts ipify through the saved proxy; it never makes a direct comparison request.

GOST v3 runs as a session child and forwards a loopback HTTP listener on port 17879 through the selected upstream. A failed or disabled proxy does not fall back to a direct connection. Browser proxy policies continue to point at that listener until restored; disabling the connection can therefore leave routed browsers offline. The listener is local to the computer, not a firewall or a multi-user isolation boundary. Proxy providers can observe connection metadata; this feature does not promise anonymity.

Credentials are stored separately in `~/.config/machinespirit/proxy-secret.json` with mode 0600. The generated GOST configuration lives in the private runtime directory. Credentials are excluded from command arguments, diagnostic responses and release archives. Changing permissions cancels in-flight shell transfers. Remote images are downloaded through the same permission checks as other requests; only raster image formats are accepted.

### Browser policies

The Browsers page supports native Linux installations of Firefox, Chrome, Chromium, LibreWolf and Zen. Unsupported package layouts, including sandboxed packages, are not silently configured. It shows existing blocking policies separately from the requested switches; a written file is not proof of runtime enforcement.

Select controls, review the exact policy preview and apply with administrator authorization. Policies affect all profiles of the selected browser. A recommendation in setup only prepares choices; browser changes require their separate Apply action. Restart the browser yourself and verify `about:policies` or `chrome://policy`. No tabs are automatically closed.

Supported controls cover usage telemetry, Firefox studies, automatic crash uploads, search suggestions, speculative loading and proxy routing. Chrome/Chromium combine usage and crash reporting in one metrics policy. LibreWolf and Zen already remove or disable telemetry; their vendor policies are preserved. Proxy routing also restricts supported direct DNS, QUIC and WebRTC paths and may affect calls. This is not a system-wide network kill switch.

Existing conflicting administrator policies are not overwritten. **Restore previous** removes only unchanged MachineSpirit-owned values and restores their originals. External modifications are reported as conflicts. Updates, certificate checks, malicious-site protection, browser profiles and saved passwords are not disabled or erased. Package upgrades may replace vendor policy files: refresh browser status after updates.

The installer installs an administrator-owned helper at `/usr/local/libexec/ms-browser-policy` and its Polkit action. User-writable scripts never run as root during browser Apply. Browser operations accept only fixed browser IDs and whitelisted boolean controls. Uninstall restores managed browser values before removing the helper; conflicts stop restoration rather than overwrite later edits.
