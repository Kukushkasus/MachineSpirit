-- [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
-- Look and feel: gaps, borders, blur. Colours follow the wallpaper via ms-theme (COLORS from hyprland.lua).
local c = COLORS

-- Effects switchboard. Override in hypr/local.lua (loaded first), e.g. for a VM or a laptop on battery:
--   FX = { blur = false, shadow = false, dim = false, rotate_border = false, low_power = true }
local fx = setmetatable(FX or {}, { __index = { blur = true, shadow = true, dim = true } })

hl.config({
    general = {
        gaps_in = 6,
        gaps_out = 12,
        border_size = 2,
        resize_on_border = true,
        extend_border_grab_area = 10,
        layout = "dwindle",
        col = {
            -- thin tonal borders: the active window carries the accent, the rest recede
            active_border   = { colors = { c.primary, c.outline, c.primary }, angle = 45 },
            inactive_border = c.outline_variant,
        },
    },
    decoration = {
        rounding = 14,
        rounding_power = 2.4,
        active_opacity = 1.0,
        inactive_opacity = 1.0,
        fullscreen_opacity = 1.0,
        dim_inactive = fx.dim,
        dim_strength = 0.10,
        shadow = {
            enabled = fx.shadow,
            range = 24,
            render_power = 3,
            color = "rgba(00000066)",
            color_inactive = "rgba(00000040)",
        },
        blur = {
            enabled = fx.blur,
            size = 7,
            passes = 3,
            noise = 0.02,
            contrast = 1.0,
            brightness = 0.95,
            vibrancy = 0.15,
            popups = true,
        },
    },
    -- a new window splits the one under the pointer, on the pointer's side
    dwindle = { preserve_split = true, smart_split = false, smart_resizing = false },
    -- every wheel notch counts (the default drops notches for 300 ms, so the wheel felt sluggish)
    binds = { scroll_event_delay = 0 },

    misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        force_default_wallpaper = 0,
    },
    input = {
        kb_layout = "us",
        kb_options = "grp:alt_shift_toggle",
        follow_mouse = 1,
        touchpad = { natural_scroll = true },
    },
})
