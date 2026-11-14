# Desktop instruments

Five widgets that live on the desktop, under the windows: Chronometer, Augury,
Cogitator, Vox receiver and Memorandum. They take their colours from the wallpaper
like the rest of the shell.

## Editing the layout

**Super+Alt+W** (or **Desktop widgets** in the Pict Archive) opens the editor.

- drag an instrument by its header, it snaps to an 8 px grid when you let go
- toggle it on or off, scale it from 80% to 140%
- click the display name to move it to another monitor
- the clock can show seconds

**Done** or **Esc** closes the editor. Windows stay on top of the instruments,
so it's easier on an empty workspace.

**Reset layout** puts everything back in place and turns all instruments on.
Notes and clock settings are kept.

From a terminal:

```sh
quickshell ipc -c machinespirit call desktop toggle
quickshell ipc -c machinespirit call desktop status
```

## Notes

Just type in the Memorandum. It saves half a second after you stop typing or when
it loses focus, the indicator shows Saved / Saving / Not saved. Turning the note
off doesn't delete it.

## Where things are stored

`$XDG_STATE_HOME/machinespirit/desktop-widgets.json`
(usually `~/.local/state/machinespirit/desktop-widgets.json`).

If the file gets broken the shell won't overwrite it and will tell you. Move it
somewhere and reload the shell to start clean.

## Multiple monitors

Each instrument remembers its monitor. If that monitor is gone, it shows up on
the first one until it's back. On small screens (the default layout needs about
800×600) the layout is squeezed to 80% for the time being, your saved positions
aren't touched.

## Data and low power

Weather comes from the same service as the bar, with the city or IP lookup set in
Privacy. If an update fails, the reading is marked STALE. The media buttons only
show what the player supports.

Low power (Settings or `MS_LOW_POWER=1`) turns off the spectrum and the decorative
effects. The scan line can be switched off on its own in Settings → Desktop & widgets.

## Tests

```sh
python3 -m unittest discover -s tools -p test_desktop_state.py
```

Multi-monitor hotplug has only been tried in a VM so far.
