# Contributing

Test in a VM or a separate session. Preserve the visual vocabulary: phosphor, instrument housings and readable controls. Motion must not delay direct manipulation.

## Checks

```sh
python3 -m unittest discover -s tools -p 'test*.py'
bash tools/test_install.sh
```

Neither command installs packages or touches your real configuration: the installer tests run in a disposable `HOME`. For QML changes, also run the actual Quickshell session, restart it from inside the Hyprland session (a hot reload does not reload every window) and read its log. Include screenshots from the running implementation, the dependency versions and any untested hardware assumptions in the pull request.

## Do not commit

Credentials, downloaded third-party wallpapers, notes or generated user settings. `wallpapers-local/`, `hypr/local.lua` and `keys.conf` are ignored on purpose. Add license information for any third-party code or assets.

## Releasing

1. Raise `VERSION` and add a matching top section to `CHANGELOG.md` (`## X.Y.Z - date`). The banner (`docs/media/banner.svg`) and both READMEs show the version too; `tools/test_release.py` fails if they disagree.
2. Run the checks above, then `python3 tools/build-release.py`. It writes `.dist/MachineSpirit-X.Y.Z.tar.gz` and `.dist/SHA256SUMS`.
3. Attach **both files, with exactly these names,** to the GitHub release tagged `vX.Y.Z`. `ms-update` downloads those names and refuses a release whose tag, archive name and inner `VERSION` differ. The checksum only catches a damaged download; nothing is signed.

The archive is built from an explicit list of paths in `tools/build-release.py`, so a stray file in your working tree cannot end up in a release. When the installer starts using a new path, add it to that list; `tools/test_release.py` compares the list with what the installer installs and fails when something is missing.

## Layout of `tools/`

`managed.py` and `make_emblem.py` are installed for users (`ms-theme` needs them). `build-release.py` builds the release, and `export-keybindings.py` regenerates `docs/KEYBINDINGS.md` from the live shortcut catalog. `make_*.py`, `svg_to_ansi.py`, `contrast_check.py` and `fake_mpris.py` are helpers for the graphics and tests. The `test_*` files and `test_install.sh` are the checks above.

## License

Submit original code contributions under GPL-3.0-only, the project license. Identify third-party material and retain its copyright and license notices; do not relicense it as your own. Bundled fonts retain their OFL licenses. See LICENSE and THIRD-PARTY.md. Describe the user-visible problem and your validation in pull requests.
