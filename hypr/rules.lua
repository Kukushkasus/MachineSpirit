-- [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
-- Window and layer rules.

-- Terminals get glassy
hl.window_rule({ match = { class = "^(kitty)$" }, opacity = "0.88 0.80" })

-- Floating dialogs
hl.window_rule({ match = { float = true }, persistent_size = true })
-- keyring and polkit prompts: centred over everything, the rest of the screen dimmed
hl.window_rule({ match = { class = "^(gcr-prompter|polkit-.*|org.kde.polkit-kde-authentication-agent-1)$" },
    float = true, center = true, pin = true, stay_focused = true, dim_around = true })
hl.window_rule({ match = { title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$" }, float = true, pin = true })

-- Shell layers: glassy bar, static wallpaper
hl.layer_rule({ match = { namespace = "machinespirit-wallpaper" }, no_anim = true })
-- Interactive instruments follow the pointer directly; layer motion otherwise trails
-- every margin update and makes Qt's global pointer mapping drift during a drag.
hl.layer_rule({ match = { namespace = "^machinespirit-desktop-(clock|weather|resources|media|notes)$" }, no_anim = true })
hl.layer_rule({ match = { namespace = "machinespirit-bar" }, blur = true, ignore_alpha = 0.3 })
hl.layer_rule({ match = { namespace = "machinespirit-popup" }, blur = true, ignore_alpha = 0.3 })
hl.layer_rule({ match = { namespace = "machinespirit-toast" }, blur = true, ignore_alpha = 0.3 })
hl.layer_rule({ match = { namespace = "machinespirit-overview" }, blur = true, ignore_alpha = 0.2 })

-- Transparent settings: blur only the panel, leaving the desktop clear.
hl.layer_rule({ match = { namespace = "machinespirit-settings" }, blur = true, ignore_alpha = 0.1 })
