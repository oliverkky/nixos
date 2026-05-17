return function(ctx)
    local wal = ctx.wal

    if ctx.primary_monitor ~= "" then
        hl.monitor({
            output = ctx.primary_monitor,
            mode = "preferred",
            position = "0x0",
            scale = 1.5,
        })
    end

    hl.env("XCURSOR_SIZE", "22")
    hl.env("HYPRCURSOR_SIZE", "22")

    hl.config({
        xwayland = {
            force_zero_scaling = true,
        },

        general = {
            gaps_in = 2,
            gaps_out = 4,
            border_size = 2,
            col = {
                active_border = { colors = { wal.color14, wal.color13 }, angle = 45 },
                inactive_border = { colors = { wal.color8, "rgba(00000000)" }, angle = 90 },
            },
            resize_on_border = false,
            allow_tearing = true,
            layout = "dwindle",
        },

        decoration = {
            rounding = 8,
            rounding_power = 2,
            active_opacity = 1.0,
            inactive_opacity = 1.0,
            dim_inactive = true,
            dim_strength = 0.10,
            shadow = {
                enabled = true,
                range = 4,
                render_power = 9,
                color = "rgba(1a1a1aaa)",
            },
            blur = {
                enabled = true,
                size = 4,
                passes = 3,
                noise = 0.05,
                vibrancy = 0.1696,
                brightness = 0.75,
                contrast = 0.75,
            },
        },

        animations = {
            enabled = true,
        },

        dwindle = {
            preserve_split = true,
        },

        master = {
            new_status = "master",
        },

        misc = {
            force_default_wallpaper = -1,
            disable_hyprland_logo = true,
        },

        input = {
            kb_layout = "cz",
            kb_variant = "",
            kb_model = "",
            kb_options = "",
            kb_rules = "",
            follow_mouse = 1,
            sensitivity = 0.0,
            touchpad = {
                natural_scroll = true,
            },
        },
    })

    hl.device({
        name = "epic-mouse-v1",
        sensitivity = -0.5,
    })
end
