# Contributing

Test in a VM or a separate session. Preserve the visual vocabulary: phosphor, instrument housings and readable controls. Motion must not delay direct manipulation.

Run `python3 -m unittest discover -s tools -p 'test*.py'` and `bash tools/test_install.sh`. For QML changes, test the actual Quickshell session and inspect its logs. Include screenshots from the running implementation, the dependency versions and any untested hardware assumptions.

Do not commit credentials, downloaded third-party wallpapers, notes or generated user settings. Add license information for any third-party code or assets. Describe the user-visible problem and validation in pull requests.

Submit original code contributions under GPL-3.0-only, the project license. Identify third-party material and retain its copyright and license notices; do not relicense it as your own. Bundled fonts retain their OFL licenses. See LICENSE and THIRD-PARTY.md.
