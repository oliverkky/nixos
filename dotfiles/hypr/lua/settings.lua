return function(ctx)
    local wal = ctx.wal
    local monitor_hdr = {}

    if ctx.monitor_hdrs ~= "" then
        for monitor in string.gmatch(ctx.monitor_hdrs, "([^;]+)") do
            local output, bitdepth, cm, sdrbrightness, sdrsaturation, supports_wide_color, supports_hdr =
                string.match(monitor, "^([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+)$")

            if output and bitdepth and cm and sdrbrightness and sdrsaturation then
                monitor_hdr[output] = {
                    bitdepth = tonumber(bitdepth) or 10,
                    cm = cm,
                    sdrbrightness = tonumber(sdrbrightness) or 1.2,
                    sdrsaturation = tonumber(sdrsaturation) or 1.0,
                    supports_wide_color = tonumber(supports_wide_color) or 0,
                    supports_hdr = tonumber(supports_hdr) or 0,
                }
            end
        end
    end

    if ctx.monitors ~= "" then
        for monitor in string.gmatch(ctx.monitors, "([^;]+)") do
            local output, mode, position, scale = string.match(monitor, "^([^,]+),([^,]+),([^,]+),([^,]+)$")

            if output and mode and position and scale then
                local monitor_config = {
                    output = output,
                    mode = mode,
                    position = position,
                    scale = tonumber(scale) or 1,
                }
                local hdr = monitor_hdr[output]

                if hdr then
                    monitor_config.bitdepth = hdr.bitdepth
                    monitor_config.cm = hdr.cm
                    monitor_config.sdrbrightness = hdr.sdrbrightness
                    monitor_config.sdrsaturation = hdr.sdrsaturation
                    monitor_config.supports_wide_color = hdr.supports_wide_color
                    monitor_config.supports_hdr = hdr.supports_hdr
                elseif not ctx.color_management then
                    -- Explicitly reset outputs that may still carry HDR state
                    -- after a config reload.
                    monitor_config.bitdepth = 8
                    monitor_config.cm = "srgb"
                    monitor_config.supports_wide_color = -1
                    monitor_config.supports_hdr = -1
                end

                hl.monitor(monitor_config)
            end
        end
    elseif ctx.primary_monitor ~= "" then
        hl.monitor({
            output = ctx.primary_monitor,
            mode = "preferred",
            position = "0x0",
            scale = ctx.primary_monitor_scale,
        })
    end

    hl.env("XCURSOR_SIZE", tostring(ctx.cursor_size))
    hl.env("HYPRCURSOR_SIZE", tostring(ctx.cursor_size))

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
                enabled = false,
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

        render = {
            cm_enabled = ctx.color_management and 1 or 0,
            cm_auto_hdr = ctx.color_management and 1 or 0,
            use_fp16 = 2,
            keep_unmodified_copy = 2,
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

    for _, device_name in ipairs({
        "razer-deathadder-v4-pro",
        "razer-deathadder-v4-pro-1",
        "razer-deathadder-v4-pro-keyboard-1",
        "razer-deathadder-v4-pro-mouse",
    }) do
        hl.device({
            name = device_name,
            sensitivity = -0.65,
        })
    end
end
