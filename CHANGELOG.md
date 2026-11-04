# Changelog

## 0.1.0-beta.1

- Preserve edits made during an in-flight settings save; guard browser policy restoration when installation paths change.

- Redesigned settings and first-launch setup with an explicit completion screen, privacy controls and browser policy batches authorized through Polkit.
- Refined the desktop chronometer with a unified time display and secondary seconds.
- Unified panel transitions and reduced-motion handling; added an 18-second VM showcase to both READMEs.
- Switched the project license to GPL-3.0-only and refreshed third-party credits.

- Added persistent user settings, monitor preview/rollback, fixed primary-output selection and English-only default keyboard layout.
- Added a searchable Super+/ manual, useful shortcuts and conflict-checked overrides.
- Added component installation, backups, guarded restore/uninstall and theme-file ownership records.
- Added a lock screen, optional original Plymouth theme, startup overlay and original wallpapers.
- Fixed broad Quickshell termination, obsolete compositor dispatch calls, screenshot error reporting, launcher state shell interpolation and destructive Qt configuration replacement.
- Reduced hidden spectrum consumers and added reduced-motion/low-power controls.
- Added real VM demonstrations, bilingual README, font licensing, recovery documentation and automated checks.

Tested in a QEMU/KVM guest. Physical hardware support still needs broader testing.
