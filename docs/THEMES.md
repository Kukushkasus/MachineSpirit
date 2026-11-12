# Theme packs

MachineSpirit has one layout and four liveries. The functions, the place of every control, the size of every click area and every reading are the same everywhere; what the shell is drawn as is not. A livery redraws every structural part of the shell: the bar's silhouette, window housings, the glass inside them, section cards and their titles, keys, icon wells, level strips, switches and sliders, workspace marks, window titles, the console, the power wheel, popups and their mounts, toasts, desktop instruments and the lock screen, and it brings its own display face.

## Wallpapers

Each pack ships one 3840×2160 wallpaper in `quickshell/themes/<id>/wallpapers/`: a machine temple (Mechanicus), a command bridge (Ultramarines), a tomb plain (Necrons) and a war forge (Khorne). Each leaves calm space at the upper left and on the right, where the instruments and the control desk sit. The Pict Archive lists them with your own pictures; nothing is copied. A fresh install starts on the machine temple. Choosing a theme never changes your wallpaper: Settings → Themes offers the pack's wallpaper as a separate button.

The pictures on the theme cards (`preview.jpg`) are screenshots of the real shell with each pack and its wallpaper.

## Liveries

The parts are drawn by `quickshell/skins/<livery>/` (`Housing`, `Glass`, `Section`, `Face`, `Well`, `Track`, `Title`, `Mark`, `BarPlate`). The shell's common parts (`Bezel`, `CrtScreen`, `SectionFrame`, `Face`, `Well`, `Track`, `Title`, `Mark`, `Mount`) load the livery's drawing behind or over their content. Only that drawing is swapped when the theme changes; what you are typing, the selected row, focus and unsaved settings stay as they are.

| | Mechanicus | Ultramarines | Necrons | Khorne |
|---|---|---|---|---|
| Bar | three plates clamped to the edge, cables with lightning | one continuous armour band, a raised command post | shards floating clear of the edge, energy conduits | iron slabs with brass teeth and a fang, spikes, a double chain |
| Housings | forged metal, rounded, slotted bolts, brass corner straps | enamel plate with four cut corners, gold rim and pinstripe, corner guards, rank pips | asymmetric monolith, energy in the edge, a free shard, glyph column | blackened iron, brass lip, saw-toothed foot, rivets, spikes |
| Glass | CRT with scanlines | tactical display: grid, ruler, gold brackets | phase glass: traces, glyphs, rising light | forge glass: ember light, scores, one dried mark on a large window |
| Cards and titles | engraved plates | gold ribbons in Roman capitals | corner brackets and a lit channel, wide letters | forged tags in black-letter |
| Keys, wells, strips | phosphor wash, round wells, segments | cut plates, gilt sockets, a ruled gauge | leaning cells, diamonds, leaning light cells | iron blocks, octagonal sockets, notched blocks |
| Display face | IBM Plex Condensed | Cinzel | Michroma | Grenze Gotisch |

The three faction faces are OFL fonts shipped in `quickshell/assets/fonts/` and loaded by the shell itself; nothing is installed system-wide. None of them has Cyrillic, so text they cannot write (and Roman numerals in Grenze, which read badly) is set in Plex.

Four packs ship with the shell:

| Pack | Materials | At the bar | Its own signs |
|---|---|---|---|
| Adeptus Mechanicus (default) | forged metal, brass, cogitator CRT | braided cables with bare copper and lightning; smoke after a strong strike, steam on a real overheat | the ticking cog, nixie tubes, warming lamps, binary on serial plates, servo-skulls |
| Ultramarines | enamelled armour, gilt trim, tactical grid | one continuous armour band with clamps; a readiness pulse runs the gold strip | a readiness dial lit by real load, laurel crest, company standards, precise motion without overshoot |
| Necrons | dark alloy, living glass with circuit traces | two energy conduits; a charge travels them, a thin arc may jump at a node | counter-turning rings, a cartouche crest, hovering shards, panels phase in rather than slide |
| Chaos: Khorne | blackened iron, battered brass, forge light | two heavy chains between toothed iron slabs; rarely one dark drop gathers and falls | a saw-toothed wheel that heaves, a horned mask, braziers, scored iron, slow heavy landings |

All graphics are made for MachineSpirit: the interface is drawn with QML shapes, the wallpapers come from the scene scripts in `tools/wallpapers/` (see its README) and the cursors from `tools/make_cursors.py`. None of it is, or may become, an official emblem or artwork.

## Motion

Every livery moves in its own way, from one shared set of timings (`common/Theme.qml`: `dEnter`, `dExit`, `dStagger`, `easeSpring`). Large windows arrive with a faction moment drawn over their housing (`common/Arrival.qml`), and their parts come up one after another (`common/Stagger.qml`):

| | Window arrives | Parts come up | At rest |
|---|---|---|---|
| Mechanicus | current runs from the crown round the frame and earths at the feet | each drops in with a relay's kick while its lamp warms | lightning on the cables, a ticking cog, flickering CRTs |
| Ultramarines | a gold pulse runs the top trim and back along the foot, then the rim answers | each slides in from the left and stops dead, in order | a readiness pulse along the armour band |
| Necrons | a phase line scans down the glass; glyphs flare where it passes | each shimmers sideways and its light wavers before it holds | motes of energy drift along the conduits |
| Khorne | a sheen of heat crosses the iron; the plate lands, jolts and throws sparks | each falls a short way and bounces once | chains that tug and settle, a dark drop that gathers and falls |

The power wheel deploys its rites from the hub in turn, the console's sectors light one after another and Settings pages come up card by card. Nothing waits for an animation: controls take input from the first frame. **Reduced motion** turns all of it off, including flashes and ambient effects; **low power** keeps only short fades.

## Cursors

Each livery has its own cursor theme: `MachineSpirit-Mechanicus`, `-Ultramarines`, `-Necrons` and `-Khorne`, with every standard shape (arrow, hand, text, resize, move, grab, crosshair, not-allowed, busy and the rest). Each shape has a dark outer and a light inner outline around the faction colours, so it stays visible on white, black and busy wallpapers. With **Settings → Appearance → Cursor → Follow faction** the pointer changes together with the theme (a preview changes it only for the running session). The themes are built on first use by `ms-cursor` into `~/.local/share/icons/` in both XCursor and hyprcursor form; **System** returns to the cursor you had before, and uninstalling MachineSpirit removes them and restores it.

## Choosing and trying

**Settings → Themes**: **Preview** dresses the running shell for 30 seconds and saves nothing: not `settings.json`, not `theme.conf`, not your wallpaper or application colours. **Keep this theme** or **Apply** makes it permanent; **Cancel**, the end of the countdown, closing the shell or a crash all bring the previous theme back. **Return to the previous theme** undoes the last apply. A pack never changes your wallpaper; each one offers its own wallpapers below the packs, applied only when you pick one.

From a terminal:

```sh
ms-theme packs                                  # every pack found, with the reason when one cannot be used
ms-theme preview necrons --mode guarded          # 5–120 s with --seconds; ms-theme preview-end stops it
ms-theme apply --pack khorne --mode faction --save
ms-theme revert
quickshell ipc -c machinespirit call theme apply ultramarines
```

While the screen is locked a theme is not applied: the request waits and is applied after you unlock. The shell is never restarted to change a theme.

## Colour modes

| Mode | What decides the colours | Old name |
|---|---|---|
| `faction` | the pack's own palette; the wallpaper has no say | `fixed` |
| `guarded` | the wallpaper's colour, folded into the faction's own hue range | `strict` |
| `follow` | the wallpaper, as matugen reads it; trim, warning colours and marks stay the pack's | `follow` |

The old names keep working and keep their meaning: an existing `theme.conf` with `mode = strict` is read as `guarded` (for Adeptus Mechanicus this is exactly what `strict` did before) and is not rewritten. In every mode the pack's anchors are kept: energy (lightning, pulses), danger (destructive actions), warning, seal and trim. Readings are lightened when needed so they stay legible on the glass.

## Your own packs

Put a folder in `~/.local/share/machinespirit/themes/<id>/` with a `theme.json` and pictures. A pack is data only: it selects built-in liveries by name and tunes them. It cannot carry QML, JavaScript, scripts or commands, and nothing in it is executed.

```json
{
  "schema": 2,
  "id": "my-forge",
  "name": "My Forge",
  "kit": "mechanicus",
  "skin": { "bar": "khorne", "type": "ultramarines" },
  "palette": {
    "seed": "#8a4b1f", "band": [10, 40], "accept": [355, 50],
    "anchors": { "energy": "#5ab8ff", "danger": "#9a2a1a", "dangerText": "#ef6a50", "warn": "#e0a800",
                 "seal": "#8e1b14", "trimLight": "#f0cf7a", "trimDark": "#8d6a27" }
  },
  "materials": { "brass": "#b88a3e" },
  "lexicon": { "panelTitle": "FORGE DESK" },
  "litanies": ["Let the current flow true"],
  "motion": { "character": "mechanical", "scale": 1, "overshoot": 2 },
  "effects": { "discharge": [4, 9], "screenLife": [40, 120], "particles": true, "messages": true, "glyphs": false },
  "wallpapers": [{ "file": "wallpapers/hall.jpg", "name": "Hall" }],
  "preview": "preview.png"
}
```

Rules, checked by `ms-theme` before anything is shown:

- `schema` is 2 (packs written for 0.2.x with schema 1 still load: every slot takes their kit). A pack made for a newer schema is listed as unavailable with the reason; the current theme stays.
- `id` matches the folder name; a built-in id cannot be taken over.
- `kit` is `mechanicus`, `ultramarines`, `necrons` or `khorne`.
- `skin` may name a livery for any of the slots `frame`, `card`, `control`, `screen`, `bar`, `instrument`, `glyph` and `type`, from the same four names. A slot left out follows `kit`; any other value is refused. It is a choice between built-in drawings, never a path or code.
- Colours are `#rrggbb`. `band` is the hue range a guarded theme folds into, `accept` the range left as it is.
- `materials` may set `metal_lo`, `metal`, `metal_hi`, `metal_edge`, `brass_lo`, `brass`, `brass_hi`, `glass`, `glass_hi`, `glow`, `glow_dim`, `glow_faint`.
- `lexicon` changes decorative words only: panel and section plates, the uptime label, the log's empty and purged lines, panel headings, instrument names, the start greeting, the motto. Settings, errors, power actions, network, security and the lock screen keep their plain words in every pack; there are no keys for them.
- Pictures: png, jpg, webp or svg only, inside the pack folder (no absolute paths, `..`, hidden paths or links), checked by their content, at most 24 MB each (svg 1 MB), 32 files and 96 MB per pack. An svg with scripts, event handlers, `foreignObject` or outside references is refused.
- Keys not listed here are ignored.

## Effects

Effects are rare and short at every level, and only one ambient effect plays at a time across the shell. **Settings → Animations & effects** sets the intensity (off, subtle, normal, lively), how often they come and which kinds you want. Reduced motion stops decorative movement, flicker and flashes; low power stops every ambient effect, the glow and the compositor's blur, shadows and animations. An effect never delays a control, never moves a reading and never shows a value that is not real: the bar's living mark follows the actual processor load, and the overheat signs (rust, sparks, steam) appear only above 85 % real CPU.
