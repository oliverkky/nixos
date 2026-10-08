return function()
    local init = os.getenv("HYPRGLASS_INIT")
    local hyprctl = os.getenv("HYPRCTL_PATH")
    if not init or init == "" then
        return
    end

    if hyprctl and hyprctl ~= "" then
        hl.permission(hyprctl, "plugin", "allow")
    end

    hl.on("hyprland.start", function()
        hl.exec_cmd(init)
    end)
end
