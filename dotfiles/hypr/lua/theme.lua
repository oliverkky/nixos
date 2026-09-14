return function(ctx)
    local colors = {
        color0 = "rgba(30343bff)",
        color8 = "rgba(5c6570ff)",
        color13 = "rgba(6697c6ff)",
        color14 = "rgba(c2c2bcff)",
    }

    local file = io.open(ctx.cache_root .. "/wallust/colors-hyprland.conf", "r")
    if not file then
        return colors
    end

    for line in file:lines() do
        local key, value = line:match("^%$(color%d+)%s*=%s*(rgba%([^%)]+%))")
        if key and value then
            colors[key] = value
        end
    end
    file:close()

    return colors
end
