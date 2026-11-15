-- [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
-- Main monitor. MS_PRIMARY comes from Settings (generated.lua); without it the fastest screen wins, then the
-- biggest. It starts on workspace 1. Screens the user hasn't placed go main first, the rest to its right.

local function area(m) return m.width * m.height end

local function primary(monitors)
    local best
    for _, m in ipairs(monitors) do
        if MS_PRIMARY and MS_PRIMARY ~= "" and m.name == MS_PRIMARY then return m end
        if not best or m.refresh_rate > best.refresh_rate + 1
            or (math.abs(m.refresh_rate - best.refresh_rate) <= 1 and area(m) > area(best)) then
            best = m
        end
    end
    return best
end

local function arrange(plugged)
    local monitors = hl.get_monitors() or {}
    local p = primary(monitors)
    if not p then return end
    local placed = MS_PLACED_OUTPUTS or {}
    if not placed[p.name] then
        hl.monitor({ output = p.name, mode = "preferred", position = "0x0", scale = "auto" })
    end
    for _, m in ipairs(monitors) do
        if m.name ~= p.name and not placed[m.name] then
            hl.monitor({ output = m.name, mode = "preferred", position = "auto-right", scale = "auto" })
        end
    end
    -- workspaces aren't tied to screens (like end-4): Super+N opens N where you are. Only the first one belongs
    -- on the main screen, so on plug-in (and at start) a screen that came up first and grabbed it gets the lowest free one instead
    if not plugged then return end
    local shown = {}
    -- the main screen is about to switch to 1, so whatever it shows now is free
    for _, m in ipairs(monitors) do if m.active_workspace and m.name ~= p.name then shown[m.active_workspace.id] = true end end
    shown[1] = true
    local function show(m, id) pcall(function() hl.get_monitor(m.name):set_workspace(tostring(id)) end) end
    for _, m in ipairs(monitors) do
        if m.name ~= p.name and m.active_workspace and m.active_workspace.id == 1 then
            local id = 2
            while shown[id] do id = id + 1 end
            shown[id] = true
            show(m, id)
            show(p, 1)
        end
    end
end

pcall(arrange)
hl.on("monitor.added", function() pcall(arrange, true) end)
hl.on("monitor.removed", function() pcall(arrange, true) end)
