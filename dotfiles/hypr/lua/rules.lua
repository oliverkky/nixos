return function(ctx)
    for workspace = 1, 9 do
        local rule = {
            workspace = tostring(workspace),
            default = workspace == 1,
            persistent = true,
        }
        if ctx.primary_monitor ~= "" then
            rule.monitor = ctx.primary_monitor
        end
        hl.workspace_rule(rule)
    end

    if ctx.secondary_monitor ~= "" and ctx.secondary_monitor_workspace then
        hl.workspace_rule({
            workspace = tostring(ctx.secondary_monitor_workspace),
            monitor = ctx.secondary_monitor,
            default = true,
            persistent = true,
        })
    end

    hl.window_rule({
        name = "kitty-opacity",
        match = { class = "kitty" },
        opacity = "0.92 0.88",
    })

    hl.window_rule({
        name = "rofi-opacity-upper",
        match = { class = "Rofi" },
        opacity = "0.96 0.96",
    })

    hl.window_rule({
        name = "rofi-opacity-lower",
        match = { class = "rofi" },
        opacity = "0.96 0.96",
    })

    hl.layer_rule({
        name = "blur-rofi",
        match = { namespace = "rofi" },
        blur = true,
        ignore_alpha = 0.0,
    })

    hl.layer_rule({
        name = "blur-quickshell",
        match = { namespace = "oliver.quickshell" },
        blur = true,
        ignore_alpha = 0.0,
    })
end
