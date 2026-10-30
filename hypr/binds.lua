-- [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
-- Keybinds. Digits are bound by physical keycode so they work on any layout (en/ru).
local mod = "SUPER"
local terminal = "kitty"
local WS = 10

local function digit(d) return "code:" .. (9 + d) end -- 1..9 => evdev codes 10..18, 10 => 19 (the 0 key)

-- Tapping Super alone opens the command console (Quickshell global shortcut "machinespirit:superTap",
-- pressed + released). Every Super+key combination below also fires "superInterrupt", so holding Super
-- for a shortcut never opens the console. Mouse drags are covered by a time limit in the shell.
local rawbind = hl.bind
local catalog = {}
local labels = {
    ["SUPER + CONTROL + Down"]="Workspaces: First empty workspace",
    ["SUPER + CONTROL + Left"]="Workspaces: Previous workspace", ["SUPER + CONTROL + Right"]="Workspaces: Next workspace",
    ["SUPER + mouse_down"]="Workspaces: Next workspace", ["SUPER + mouse_up"]="Workspaces: Previous workspace",
    ["SUPER + CONTROL + mouse_down"]="Workspaces: Next occupied workspace", ["SUPER + CONTROL + mouse_up"]="Workspaces: Previous occupied workspace",
    ["XF86AudioRaiseVolume"]="Audio: Volume up", ["XF86AudioLowerVolume"]="Audio: Volume down",
    ["XF86AudioMute"]="Audio: Toggle mute", ["XF86AudioMicMute"]="Audio: Toggle microphone mute",
    ["XF86AudioPlay"]="Media: Play or pause", ["XF86AudioNext"]="Media: Next track", ["XF86AudioPrev"]="Media: Previous track",
    ["SUPER + Return"]="Apps: Terminal", ["SUPER + E"]="Apps: File manager", ["SUPER + B"]="Apps: Browser",
    ["SUPER + W"]="Shell: Wallpaper archive", ["SUPER + Space"]="Shell: Command console", ["SUPER + Tab"]="Shell: Workspace overview",
    ["SUPER + ALT + W"]="Desktop: Edit widgets", ["SUPER + Q"]="Windows: Close", ["SUPER + F"]="Windows: Fullscreen",
    ["SUPER + D"]="Windows: Maximize", ["SUPER + J"]="Windows: Toggle split", ["SUPER + ALT + Space"]="Windows: Toggle floating",
    ["ALT + Tab"]="Windows: Cycle", ["SUPER + S"]="Windows: Toggle scratchpad", ["SUPER + CONTROL + S"]="Windows: Send to scratchpad",
    ["SUPER + N"]="Shell: Control panel", ["SUPER + SHIFT + E"]="Session: Power menu", ["SUPER + SHIFT + R"]="Session: Reload configuration",
    ["Print"]="Capture: Region", ["SUPER + Print"]="Capture: Full desktop", ["CONTROL + SHIFT + Escape"]="Apps: System monitor",
    ["SUPER + mouse:272"]="Windows: Drag", ["SUPER + mouse:273"]="Windows: Resize"
}
for _, direction in ipairs({"Left","Right","Up","Down"}) do
    labels["SUPER + " .. direction] = "Windows: Focus " .. direction
    labels["SUPER + SHIFT + " .. direction] = "Windows: Move " .. direction
end
for i=1,10 do
    labels["SUPER + " .. digit(i)]="Workspaces: Switch to " .. i
    labels["SUPER + SHIFT + " .. digit(i)]="Workspaces: Move and follow to " .. i
    labels["SUPER + ALT + " .. digit(i)]="Workspaces: Send to " .. i
end
local function bind(keys, dispatcher, opts)
    local original = keys
    opts = opts or {}
    opts.description = opts.description or labels[keys] or ("Controls: " .. keys)
    local actual = (MS_BINDINGS or {})[keys]
    table.insert(catalog, { original=original, keys=actual or keys, description=opts.description })
    if actual == "" then return end
    keys = actual or keys
    rawbind(keys, dispatcher, opts)
    if keys:find(mod, 1, true) and not keys:find("mouse:", 1, true) then
        rawbind(keys, hl.dsp.global("machinespirit:superInterrupt"), { transparent = true })
    end
end
hl.bind = bind
-- the press of Super itself (arms the tap) and its release with Super held (fires it)
rawbind("SUPER_L", hl.dsp.global("machinespirit:superDown"), { ignore_mods = true, transparent = true })
rawbind("SUPER_R", hl.dsp.global("machinespirit:superDown"), { ignore_mods = true, transparent = true })
rawbind(mod .. " + SUPER_L", hl.dsp.global("machinespirit:superTap"), { description = "Shell: command console (tap Super)" })
rawbind(mod .. " + SUPER_R", hl.dsp.global("machinespirit:superTap"))

-- Desktop instrument editor
hl.bind(mod .. " + ALT + W", hl.dsp.exec_cmd("quickshell ipc -c machinespirit call desktop toggle"))

-- Apps
hl.bind(mod .. " + Return", hl.dsp.exec_cmd(terminal))
hl.bind(mod .. " + E",      hl.dsp.exec_cmd("dolphin"))
hl.bind(mod .. " + W",      hl.dsp.exec_cmd("quickshell ipc -c machinespirit call walls toggle"))
hl.bind(mod .. " + B",      hl.dsp.exec_cmd("firefox"))
hl.bind("CONTROL + SHIFT + Escape", hl.dsp.exec_cmd(terminal .. " -e btop"))

-- Command console: also on Super+Space, and Super+Tab with the keyboard on the sectors
hl.bind(mod .. " + Space", hl.dsp.exec_cmd("quickshell ipc -c machinespirit call launcher toggle"))
hl.bind(mod .. " + Tab",   hl.dsp.exec_cmd("quickshell ipc -c machinespirit call overview toggle"))

-- Windows
hl.bind(mod .. " + Q",          hl.dsp.window.close())
hl.bind(mod .. " + ALT + Space", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mod .. " + F",          hl.dsp.window.fullscreen())
hl.bind(mod .. " + D",          hl.dsp.window.fullscreen({ mode = 1 }))
hl.bind(mod .. " + J",          hl.dsp.layout("togglesplit"))
hl.bind("ALT + Tab",            hl.dsp.window.cycle_next())

-- Focus / move windows
hl.bind(mod .. " + Left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mod .. " + Right", hl.dsp.focus({ direction = "right" }))
hl.bind(mod .. " + Up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mod .. " + Down",  hl.dsp.focus({ direction = "down" }))
hl.bind(mod .. " + SHIFT + Left",  hl.dsp.window.move({ direction = "l" }))
hl.bind(mod .. " + SHIFT + Right", hl.dsp.window.move({ direction = "r" }))
hl.bind(mod .. " + SHIFT + Up",    hl.dsp.window.move({ direction = "u" }))
hl.bind(mod .. " + SHIFT + Down",  hl.dsp.window.move({ direction = "d" }))

-- Mouse: drag and resize
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag())
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize())

-- Workspaces: SUPER+1..0 switch, SUPER+SHIFT+1..0 send window
for i = 1, WS do
    hl.bind(mod .. " + " .. digit(i),             hl.dsp.focus({ workspace = i }))
    hl.bind(mod .. " + SHIFT + " .. digit(i),     hl.dsp.window.move({ workspace = i }))
    hl.bind(mod .. " + ALT + " .. digit(i),       hl.dsp.window.move({ workspace = i, follow = false }))
end
hl.bind(mod .. " + CONTROL + Right", hl.dsp.focus({ workspace = "+1" }))
hl.bind(mod .. " + CONTROL + Left",  hl.dsp.focus({ workspace = "-1" }))
hl.bind(mod .. " + CONTROL + Down",  hl.dsp.focus({ workspace = "empty" }))
-- wheel: down goes to the next sector, up to the previous; with Ctrl only through occupied ones
hl.bind(mod .. " + mouse_down",             hl.dsp.focus({ workspace = "+1" }))
hl.bind(mod .. " + mouse_up",               hl.dsp.focus({ workspace = "-1" }))
hl.bind(mod .. " + CONTROL + mouse_down",   hl.dsp.focus({ workspace = "r+1" }))
hl.bind(mod .. " + CONTROL + mouse_up",     hl.dsp.focus({ workspace = "r-1" }))

-- Scratchpad
hl.bind(mod .. " + S",         hl.dsp.workspace.toggle_special())
hl.bind(mod .. " + CONTROL + S", hl.dsp.window.move({ workspace = "special" }))

-- Audio / media (PipeWire)
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 3%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 3%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true })
hl.bind("XF86AudioPlay",        hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioNext",        hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPrev",        hl.dsp.exec_cmd("playerctl previous"),   { locked = true })

-- Screenshots (region select with overlay; saved to ~/Pictures/Screenshots and copied)
local shot = os.getenv("HOME") .. "/.local/bin/ms-screenshot"
hl.bind("Print",           hl.dsp.exec_cmd(shot .. " region"))
hl.bind(mod .. " + Print", hl.dsp.exec_cmd(shot .. " full"))

-- Session
hl.bind(mod .. " + SHIFT + R", hl.dsp.exec_cmd("hyprctl reload"))
hl.bind(mod .. " + SHIFT + E", hl.dsp.exec_cmd("quickshell ipc -c machinespirit call power toggle"))
hl.bind(mod .. " + N",         hl.dsp.exec_cmd("quickshell ipc -c machinespirit call sanctum toggle"))

-- Instrument manual and useful daily rites.
hl.bind(mod .. " + code:61", hl.dsp.exec_cmd("quickshell ipc -c machinespirit call manual toggle"), { description = "Help: All keybindings" })
hl.bind(mod .. " + comma", hl.dsp.exec_cmd("quickshell ipc -c machinespirit call settings toggle"), { description = "Shell: Settings" })
hl.bind(mod .. " + L", hl.dsp.exec_cmd("ms-session lock"), { description = "Session: Lock" })
hl.bind("CONTROL + ALT + Delete", hl.dsp.exec_cmd("quickshell ipc -c machinespirit call power toggle"), { description = "Session: Power menu" })
hl.bind(mod .. " + SHIFT + S", hl.dsp.exec_cmd(shot .. " region"), { description = "Capture: Select screenshot region" })
hl.bind(mod .. " + SHIFT + P", hl.dsp.exec_cmd("playerctl play-pause"), { description = "Media: Play or pause" })
hl.bind(mod .. " + SHIFT + N", hl.dsp.exec_cmd("playerctl next"), { description = "Media: Next track" })
hl.bind(mod .. " + SHIFT + B", hl.dsp.exec_cmd("playerctl previous"), { description = "Media: Previous track" })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl set +5%"), { repeating = true, description = "Display: Brightness up" })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 5%-"), { repeating = true, description = "Display: Brightness down" })
for key, delta in pairs({ minus = -0.25, equal = 0.25 }) do
    hl.bind(mod .. " + " .. key, function()
        hl.config({cursor = {zoom_factor = math.max(1, math.min(3, hl.get_config("cursor:zoom_factor") + delta))}})
    end, { repeating = true, description = "Display: Zoom " .. (delta > 0 and "in" or "out") })
end

hl.bind = rawbind
-- Publish the same registrations the compositor uses; no separately maintained help list.
local path = (os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")) .. "/machinespirit/bindings.json"
local file = io.open(path .. ".tmp", "w")
if file then
    file:write("[")
    for i, b in ipairs(catalog) do
        if i > 1 then file:write(",") end
        file:write(string.format('{"original":%q,"keys":%q,"description":%q}', b.original, b.keys, b.description))
    end
    file:write("]"); file:close(); os.rename(path .. ".tmp", path)
end
