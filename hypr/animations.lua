-- [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
-- Animations: springy window open/close, sliding workspaces, rotating border glow.
-- Material 3 motion: standard and emphasized-decelerate curves, no overshoot.
hl.curve("standard", { type = "bezier", points = { {0.2, 0},    {0, 1}   } })
hl.curve("decel",    { type = "bezier", points = { {0.05, 0.7}, {0.1, 1} } })
hl.curve("accel",    { type = "bezier", points = { {0.3, 0},    {0.8, 0.15} } })
hl.curve("linear",   { type = "bezier", points = { {0, 0},      {1, 1}   } })

hl.config({ animations = { enabled = true } })

hl.animation({ leaf = "global",      enabled = true, speed = 4,  bezier = "standard" })
hl.animation({ leaf = "windowsIn",   enabled = true, speed = 4,  bezier = "decel",    style = "popin 88%" })
hl.animation({ leaf = "windowsOut",  enabled = true, speed = 3,  bezier = "accel",    style = "popin 92%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 4,  bezier = "standard" })
hl.animation({ leaf = "fade",        enabled = true, speed = 3,  bezier = "standard" })
hl.animation({ leaf = "border",      enabled = true, speed = 5,  bezier = "standard" })
hl.animation({ leaf = "workspaces",  enabled = true, speed = 4,  bezier = "decel",    style = "slidefade 12%" })
hl.animation({ leaf = "layers",      enabled = true, speed = 3,  bezier = "decel",    style = "popin 94%" })
hl.animation({ leaf = "fadeLayers",  enabled = true, speed = 3,  bezier = "standard" })
