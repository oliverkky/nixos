return function(ctx)
    local main_mod = ctx.main_mod
    local function bind(keys, dispatcher, opts)
        hl.bind(keys, dispatcher, opts or {})
    end

    bind(main_mod .. " + RETURN", hl.dsp.exec_cmd(ctx.terminal))
    bind(main_mod .. " + C", hl.dsp.window.close())
    bind(main_mod .. " + M", hl.dsp.exec_cmd("uwsm stop"))
    bind(main_mod .. " + E", hl.dsp.exec_cmd(ctx.file_manager))
    bind(main_mod .. " + V", hl.dsp.window.float({ action = "toggle" }))
    bind(main_mod .. " + F", hl.dsp.window.fullscreen({ action = "toggle" }))
    bind(main_mod .. " + SPACE", hl.dsp.exec_cmd(ctx.menu))
    bind(main_mod .. " + CTRL + SPACE", hl.dsp.exec_cmd("qs ipc call calendarMedia open"))
    bind(main_mod .. " + SHIFT + V", hl.dsp.exec_cmd("desktopctl clipboard menu"))
    bind(main_mod .. " + P", hl.dsp.exec_cmd("qs ipc call displayMenu openLayout"))
    bind(main_mod .. " + SHIFT + P", hl.dsp.exec_cmd("qs ipc call displayMenu openCurrent"))
    bind(main_mod .. " + Z", hl.dsp.exec_cmd(ctx.zed))
    bind(main_mod .. " + O", hl.dsp.exec_cmd("obsidian"))
    bind(main_mod .. " + B", hl.dsp.exec_cmd("brave"))
    bind(main_mod .. " + W", hl.dsp.exec_cmd("systemctl --user restart quickshell.service"))
    bind(main_mod .. " + ESCAPE", hl.dsp.exec_cmd("qs ipc call systemMenu open"))
    bind(main_mod .. " + SHIFT + W", hl.dsp.exec_cmd("waypaper"))
    bind(main_mod .. " + SHIFT + S", hl.dsp.exec_cmd("qs ipc call screenshotMenu open"))
    bind("CTRL + SHIFT + ESCAPE", hl.dsp.exec_cmd("missioncenter"))

    bind(main_mod .. " + CTRL + B", hl.dsp.exec_cmd("qs ipc call statusPanel toggle bluetooth"))
    bind(main_mod .. " + CTRL + N", hl.dsp.exec_cmd("qs ipc call statusPanel toggle network"))
    bind(main_mod .. " + CTRL + W", hl.dsp.exec_cmd("qs ipc call statusPanel toggle network"))
    bind(main_mod .. " + CTRL + S", hl.dsp.exec_cmd("qs ipc call statusPanel toggle audio"))
    bind(main_mod .. " + CTRL + V", hl.dsp.exec_cmd("qs ipc call statusPanel toggle audio"))
    bind(main_mod .. " + CTRL + P", hl.dsp.exec_cmd("qs ipc call statusPanel toggle battery"))

    bind(main_mod .. " + h", hl.dsp.focus({ direction = "left" }))
    bind(main_mod .. " + l", hl.dsp.focus({ direction = "right" }))
    bind(main_mod .. " + k", hl.dsp.focus({ direction = "up" }))
    bind(main_mod .. " + j", hl.dsp.focus({ direction = "down" }))
    bind(main_mod .. " + LEFT", hl.dsp.focus({ direction = "left" }))
    bind(main_mod .. " + RIGHT", hl.dsp.focus({ direction = "right" }))
    bind(main_mod .. " + UP", hl.dsp.focus({ direction = "up" }))
    bind(main_mod .. " + DOWN", hl.dsp.focus({ direction = "down" }))

    bind(main_mod .. " + SHIFT + h", hl.dsp.window.move({ direction = "left" }))
    bind(main_mod .. " + SHIFT + l", hl.dsp.window.move({ direction = "right" }))
    bind(main_mod .. " + SHIFT + k", hl.dsp.window.move({ direction = "up" }))
    bind(main_mod .. " + SHIFT + j", hl.dsp.window.move({ direction = "down" }))
    bind(main_mod .. " + SHIFT + LEFT", hl.dsp.window.move({ direction = "left" }))
    bind(main_mod .. " + SHIFT + RIGHT", hl.dsp.window.move({ direction = "right" }))
    bind(main_mod .. " + SHIFT + UP", hl.dsp.window.move({ direction = "up" }))
    bind(main_mod .. " + SHIFT + DOWN", hl.dsp.window.move({ direction = "down" }))

    local workspace_keys = {
        plus = 1,
        ecaron = 2,
        scaron = 3,
        ccaron = 4,
        rcaron = 5,
        zcaron = 6,
        yacute = 7,
        aacute = 8,
        iacute = 9,
    }

    for key, workspace in pairs(workspace_keys) do
        bind(main_mod .. " + " .. key, hl.dsp.focus({ workspace = workspace }))
        bind(main_mod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = workspace }))
    end

    bind(main_mod .. " + Y", hl.dsp.workspace.toggle_special("magic"))
    bind(main_mod .. " + SHIFT + Y", hl.dsp.window.move({ workspace = "special:magic" }))

    bind(main_mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
    bind(main_mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

    bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("desktopctl audio volume-up"),
        { locked = true, repeating = true })
    bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("desktopctl audio volume-down"),
        { locked = true, repeating = true })
    bind("XF86AudioMute", hl.dsp.exec_cmd("desktopctl audio volume-mute"),
        { locked = true, repeating = true })
    bind("XF86AudioMicMute", hl.dsp.exec_cmd("desktopctl audio mic-mute"),
        { locked = true, repeating = true })
    bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("desktopctl brightness up"),
        { locked = true, repeating = true })
    bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("desktopctl brightness down"),
        { locked = true, repeating = true })

    bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
    bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
    bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
    bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
end
