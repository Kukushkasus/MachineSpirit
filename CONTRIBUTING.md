# Contributing

Work in a virtual machine or a separate session, not on the desktop you depend on. Keep the visual vocabulary: phosphor screens, instrument housings and readable controls. Motion must never delay direct manipulation, and everything decorative must stop with reduced motion.

## Checks

```sh
python3 -m unittest discover -s tools -p 'test*.py'
bash tools/test_install.sh
```

Neither command installs packages or touches your real configuration: the installer tests run in a disposable `HOME`. The login and lock tests use a fake root and fake `systemctl`, `quickshell` and `hyprlock`, so they prove the logic, not the real thing. A change to `installer/login.py`, the SDDM theme (`assets/sddm/`) or the lock screen (`quickshell/modules/lock/`) also needs a real reboot and sign-in. The SDDM theme can be checked without installing it: `sddm-greeter-qt6 --test-mode --theme assets/sddm/machinespirit` inside a Wayland session.

For QML changes, run the real Quickshell session, restart it from inside Hyprland (`ms-session restart`; a hot reload does not reload every window) and read its log (`quickshell log -c machinespirit`). The shell stops reloading while the screen is locked, so unlock before testing.

In a pull request, describe the user-visible problem, include screenshots or a short recording of the running result, the versions of Hyprland and Quickshell, and any hardware you could not test.

## Do not commit

Credentials, downloaded third-party wallpapers, notes or generated user settings. `wallpapers-local/`, `hypr/local.lua` and `keys.conf` are ignored on purpose. Add license information for any third-party code or assets.

## Releasing

1. Raise `VERSION`, rename the `## Unreleased` section of `CHANGELOG.md` to `## X.Y.Z - date`, and update the version in the banner (`docs/media/banner.svg`) and both READMEs; `tools/test_release.py` fails if they disagree.
2. Run the checks, then `python3 tools/build-release.py OUTDIR`. It writes `OUTDIR/MachineSpirit-X.Y.Z.tar.gz` and `OUTDIR/SHA256SUMS`. Without `OUTDIR` it writes to `.dist/`, which also holds `MachineSpirit-0.2.0.tar.gz`, the reference archive the update tests install from; keep that file (`gh release download v0.2.0 -D .dist` brings it back).
3. Attach **both files, with exactly these names,** to the GitHub release tagged `vX.Y.Z`. `ms-update` downloads those names and refuses a release whose tag, archive name and inner `VERSION` differ. The checksum only catches a damaged download; nothing is signed.

The archive is built from an explicit list of paths in `tools/build-release.py`, so a stray file in your working tree cannot end up in a release. When the installer starts using a new path, add it to that list; `tools/test_release.py` compares the list with what the installer installs.

## Layout of `tools/`

- Installed for users: `managed.py` (transactions for ms-theme), `make_emblem.py` (the terminal emblem), `make_cursors.py` (the cursor themes, built by `ms-cursor`).
- Release and docs: `build-release.py`, `export-keybindings.py` (regenerates `docs/KEYBINDINGS.md` from the live shortcut catalog).
- Graphics: `make_svg.py`, `make_fx.py`, `svg_to_ansi.py`, `contrast_check.py`.
- Tests: `test_*.py`, `test_install.sh`, and `fake_mpris.py` (a fake media player for checking the player panels).

## License

Submit original code under GPL-3.0-only, the project license. Identify third-party material and keep its copyright and license notices; do not relicense it as your own. Bundled fonts keep their OFL licenses. See LICENSE and THIRD-PARTY.md.
