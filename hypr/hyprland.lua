-- [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
-- MachineSpirit: Hyprland config (Lua, Hyprland >= 0.55)
-- https://wiki.hypr.land/Configuring/Start/

hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })

-- machine-local overrides (e.g. the dev VM); not part of the repo
pcall(require, "local")
if FX and FX.low_power then hl.env("MS_LOW_POWER", "1") end

hl.env("PATH", os.getenv("HOME") .. "/.local/bin:" .. (os.getenv("PATH") or "/usr/bin"))
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

hl.on("hyprland.start", function()
    hl.exec_cmd("ms-session start")
    hl.exec_cmd("/usr/lib/polkit-kde-authentication-agent-1")
    -- the keyring that keeps app passwords (browsers, mail, git); unlocked at login by pam_gnome_keyring
    hl.exec_cmd("sh -c 'command -v gnome-keyring-daemon >/dev/null && gnome-keyring-daemon --start --components=secrets,pkcs11'")
end)

-- colours come from ms-theme (wallpaper); before the first run the built-in scheme is used
local ok, colors = pcall(require, "colors")
COLORS = ok and colors or require("colors_default")
-- Qt apps: the KDE platform theme reads the wallpaper colours from kdeglobals and the rounded Darkly style;
-- without plasma-integration fall back to qt6ct
local function exists(p) local f = io.open(p, "r"); if f then f:close() return true end return false end
if os.getenv("QT_QPA_PLATFORMTHEME") == nil then
    hl.env("QT_QPA_PLATFORMTHEME", exists("/usr/lib/qt6/plugins/platformthemes/KDEPlasmaPlatformTheme6.so") and "kde" or "qt6ct")
end
hl.env("GTK_THEME", "adw-gtk3-dark")

-- virtio-gpu (QEMU/virgl): Hyprland 0.57 hides dmabuf formats KMS cannot import, Qt then picks one without
-- alpha and the shell's overlays come up black (Hyprland discussion #16703). Only in VMs; real GPUs are fine.
local function virtio_gpu()
    for i = 0, 3 do
        local f = io.open("/sys/class/drm/card" .. i .. "/device/vendor", "r")
        if f then local v = f:read("*l"); f:close(); if v == "0x1af4" then return true end end
    end
    return false
end
if virtio_gpu() then pcall(hl.config, { quirks = { skip_non_kms_dmabuf_formats = false } }) end

require("look")
require("animations")
local userSettings = (os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")) .. "/machinespirit/generated.lua"
local loaded, err = pcall(dofile, userSettings)
if not loaded then print("MachineSpirit settings: " .. tostring(err)) end
require("binds")
require("rules")
