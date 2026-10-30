# Desktop instruments

Five independent instruments sit above the wallpaper and below application windows:
Chronometer, Augury, Cogitator, Vox receiver and Memorandum. Their palette follows
MachineSpirit's wallpaper colours. Sizes use logical pixels.

Open the editor with **Super+Alt+W**, or **Desktop widgets** in Pict Archive.
Select an instrument, drag its header (snaps to an 8 px grid on release), toggle visibility, adjust scale from 80% to
140%, or click the display name to cycle displays. The clock has an optional
seconds display. **Done** or **Escape** closes the editor. Use an empty workspace
when arranging instruments, since applications remain above them.

Notes are edited directly and saved after 500 ms without input or when focus
leaves the editor. Text is plain text, including Unicode and multiline content.
Watch the Saved / Saving / Not saved indicator. Disabling a note does not erase it.
Reset layout restores the placement and enables all instruments; it keeps note
content and clock preferences.

State is stored in `$XDG_STATE_HOME/machinespirit/desktop-widgets.json`, falling
back to `~/.local/state/machinespirit/desktop-widgets.json`. Writes are private
(mode 0600) and atomic. A damaged file or unsupported format is preserved and
reported; back it up and rename it before reloading the shell to start fresh.
The editor is also available through:

```sh
quickshell ipc -c machinespirit call desktop toggle
quickshell ipc -c machinespirit call desktop status
```

Each instrument remembers its display. Unavailable displays temporarily fall back
to the first available one. Small displays reflow overflowing saved layouts at
80% without replacing the original positions. Moving or resizing an instrument
commits its placement for the current display size. A display must have at least
800×600 logical pixels to fit the default five-instrument layout.

The weather service supplies its existing location (`MS_WEATHER_LOCATION` or IP
lookup); failed updates mark existing readings STALE. Media buttons follow MPRIS
capabilities. Missing artwork and missing players have explicit empty states.
CPU/RAM/network use the existing Sys service. Cava is shared with other shell
consumers and released when the instrument is unloaded or lowPower is active.
The desktop adds no separate weather or system polling processes.

Low power (`MS_LOW_POWER=1`) disables the spectrum and decorative effects.
The note never flickers while being edited. Ordinary input only reaches the
individual instrument windows; the spaces between them remain click-through.

Persistence regression checks:

```sh
python3 -m unittest discover -s tools -p test_desktop_state.py
```

Development and visual validation take place in the MachineSpirit VM. Real
multi-monitor hotplug still needs hardware validation.

During editing, each instrument moves inside a stationary, input-masked surface;
this avoids compositor movement easing and Wayland global-coordinate drift.
Closing the editor restores compact instrument-sized surfaces. Hyprland disables
layer animations only for the five desktop instrument namespaces.
