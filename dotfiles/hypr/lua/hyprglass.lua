return function()
    local init = os.getenv("HYPRGLASS_INIT")
    local hyprctl = os.getenv("HYPRCTL_PATH")
    if hyprctl and hyprctl ~= "" then
        hl.permission(hyprctl, "plugin", "allow")
    end

    local glass = hl.plugin.hyprglass
    if glass then
        glass.config({
            default_theme = "dark",
            default_preset = "pomme",
            manage_window_blur = true,
            layers = {
                enabled = true,
                preset = "pomme",
                mask_mode = "alpha",
            },
        })
        glass.layer("oliver.quickshell", { mask_mode = "alpha", mask_threshold = 0.03 })
        glass.layer("oliver.quickshell.popover", { mask_mode = "alpha", mask_threshold = 0.03 })
        glass.layer("oliver.quickshell.notifications", { mask_mode = "alpha", mask_threshold = 0.03 })
        glass.layer("oliver.quickshell.screenshot", { mask_mode = "alpha", mask_threshold = 0.03 })
        glass.layer("oliver.quickshell.clipboard", { mask_mode = "alpha", mask_threshold = 0.03 })
        return
    end

    if not init or init == "" then
        return
    end

    hl.on("hyprland.start", function()
        hl.exec_cmd(init)
    end)
end
