# Verification ledger

Dates: 2026-10-30 / 2026-10-31 (Asia/Sakhalin). This is a beta inspection record, not a claim of universal hardware support.

## Environment

CachyOS in QEMU/KVM, virtio/virgl graphics, 4 vCPUs, 4 GiB RAM. Hyprland 0.57.0, Quickshell 0.3.2, Matugen 4.2.0. Primary test resolution 1908×996. Tests used the existing development profile and a newly created disposable user profile with empty application configuration. This was not a fresh OS installation in a second VM.

## Confirmed

- 13 Python data/transaction tests and the isolated installer smoke test pass, including when run from a separately extracted release archive. Dry-run creates no configuration; update and uninstall preserve user edits; rollback restores file contents and symlinks.
- The complete `--full --no-packages --yes` path, including boot regeneration, completed successfully on the provisioned VM. Dependency installation was exercised separately for missing packages.
- All user components install into the clean profile and the shell starts automatically after a VM reboot. Only one MachineSpirit renderer and one managed idle process run.
- Super+/ opens the live shortcut manual in English and Russian layouts; Escape closes it. Adding `us,ru` through the GUI was saved successfully. A conflicting remap was rejected before changing the configuration. A syntactically accepted but unknown Hyprland key was rejected by the compositor; the old configuration was restored and reloaded with no remaining errors. Settings and its display/keybinding pages render in the real session.
- Monitor preview changed Virtual-1 from 1908×996 to 1360×768. Without confirmation, the watchdog restored the original configuration and 1908×996.
- A second virtual output was created. Settings opened on the pinned output; removing it moved Settings back to Virtual-1. A disappearing-window bug found by this test was fixed.
- Widget dragging tracks actual pointer displacement. A 200×120 pointer move produced the same widget displacement, followed by release snapping.
- Switching low-power mode off originally moved bar contents out of view. Startup-position binding was corrected; the bar remains visible after toggling both ways.
- Real Hyprlock/PAM test in the disposable account: a wrong password kept the screen locked; the correct password unlocked it. No real user password was requested or stored.
- Plymouth/initramfs/GRUB installation completed and the VM booted successfully. Plymouth start/quit is present in the boot journal. The full transition has not been visually certified on physical hardware.
- Kitty starts the selected fish integration with the themed prompt and fastfetch; no startup errors were shown.
- README media was captured from the running clean profile with a bundled original wallpaper, not generated mockups.

## Performance sample

Same renderer, five widgets, no media playing, 6-second samples after startup:

| Mode | CPU (% of one core) | Renderer RSS |
|---|---:|---:|
| Normal | 9.8% | 366.0 MiB |
| Low power | 3.3% | 368.7 MiB |

Short VM samples are noisy and include the current widget configuration. They are not hardware-wide performance guarantees. GIF recording substantially increases CPU and was not running during these samples.

## Limits and follow-up

- Physical NVIDIA, Bluetooth adapters, DDC brightness and physical monitor hotplug were not tested. Virtual outputs do not certify real cables/EDID/refresh rates.
- Suspend/resume locked the test session correctly. This virtio/virgl VM logged DRM resource errors after resume; authentication succeeded but needed output reactivation before the lock animation completed. A delayed DPMS reactivation was added. Physical GPU resume still needs validation.
- Boot integration currently supports GRUB + mkinitcpio without a display manager. Other bootloader/login arrangements are deliberately not changed.
- Qt/Wayland text-input focus warnings and an absent Bluetooth D-Bus service were observed in the VM. They did not prevent the tested UI interactions.
- API wallpaper providers depend on connectivity, rate limits and user credentials; these external services are not guaranteed by the release.
- CI is configured in the repository but has not run on GitHub before publication.
