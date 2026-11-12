# Faction wallpapers

The four 3840×2160 wallpapers in `quickshell/themes/<id>/wallpapers/` are rendered from these scene scripts. Every shape, material and light is made in code; no outside models, textures or artwork are used.

```sh
blender -b -P tools/wallpapers/<id>.py -- --out out.png
```

`common.py` holds the shared scene helpers; `mechanicus.py`, `ultramarines.py`, `necrons.py` and `khorne.py` build one scene each (a machine temple, a command bridge, a tomb plain and a war forge). Each scene leaves calm space at the upper left and on the right, where the desktop instruments and the control desk sit. Tested with Blender 4.5 LTS (Cycles). The shipped files are JPEG, quality 95, 4:4:4.
