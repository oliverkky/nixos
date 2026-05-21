return function(ctx)
    local main_mod = ctx.main_mod

    local function gesture(spec)
        hl.gesture(spec)
    end

    -- Existing touchpad workspace/fullscreen/special gestures, moved from
    -- libinput-gestures to native Hyprland gestures.
    gesture({
        fingers = 3,
        direction = "left",
        action = function()
            hl.dispatch(hl.dsp.focus({ workspace = "e+1" }))
        end,
    })

    gesture({
        fingers = 3,
        direction = "right",
        action = function()
            hl.dispatch(hl.dsp.focus({ workspace = "e-1" }))
        end,
    })

    gesture({
        fingers = 3,
        direction = "up",
        action = function()
            hl.dispatch(hl.dsp.window.fullscreen({ action = "set" }))
        end,
    })

    gesture({
        fingers = 3,
        direction = "down",
        action = function()
            hl.dispatch(hl.dsp.window.fullscreen({ action = "unset" }))
        end,
    })

    gesture({
        fingers = 3,
        direction = "pinchin",
        action = "special",
        workspace_name = "magic",
    })

    gesture({
        fingers = 3,
        direction = "pinchout",
        action = "special",
        workspace_name = "magic",
    })

    -- SUPER + 3-finger swipe: move the active window in the layout.
    gesture({
        fingers = 3,
        direction = "left",
        mods = main_mod,
        action = "move",
    })

    gesture({
        fingers = 3,
        direction = "right",
        mods = main_mod,
        action = "move",
    })

    gesture({
        fingers = 3,
        direction = "up",
        mods = main_mod,
        action = "move",
    })

    gesture({
        fingers = 3,
        direction = "down",
        mods = main_mod,
        action = "move",
    })

    -- SUPER + SHIFT + 3-finger horizontal swipe: move the active window to the
    -- previous/next workspace on this monitor and follow it there.
    gesture({
        fingers = 3,
        direction = "left",
        mods = main_mod .. " SHIFT",
        action = function()
            hl.dispatch(hl.dsp.window.move({ workspace = "r-1", follow = true }))
        end,
    })

    gesture({
        fingers = 3,
        direction = "right",
        mods = main_mod .. " SHIFT",
        action = function()
            hl.dispatch(hl.dsp.window.move({ workspace = "r+1", follow = true }))
        end,
    })
end
