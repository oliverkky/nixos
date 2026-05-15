-- Hyprland 0.55+ Lua config.
-- Legacy Hyprlang files remain in this directory as rollback/reference only.

local home = os.getenv("HOME") or "/home/oliver"
local config_root = os.getenv("XDG_CONFIG_HOME") or (home .. "/.config")

local terminal = "kitty"
local fileManager = "nautilus"
local menu = "rofi -show drun"
local zed = "zeditor"
local mainMod = "SUPER"

local function read_wal_colors()
    local colors = {
        color8 = "rgba(5c6570ff)",
        color13 = "rgba(6697c6ff)",
        color14 = "rgba(c2c2bcff)",
    }

    local file = io.open(home .. "/.cache/wal/colors-hyprland.conf", "r")
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

local wal = read_wal_colors()

hl.monitor({
    output = "eDP-1",
    mode = "preferred",
    position = "0x0",
    scale = 1.5,
})

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

hl.curve("easeOutQuint", { type = "bezier", points = { { 0.23, 1 }, { 0.32, 1 } } })
hl.curve("easeInOutCubic", { type = "bezier", points = { { 0.65, 0.05 }, { 0.36, 1 } } })
hl.curve("linear", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })
hl.curve("almostLinear", { type = "bezier", points = { { 0.5, 0.5 }, { 0.75, 1 } } })
hl.curve("quick", { type = "bezier", points = { { 0.15, 0 }, { 0.1, 1 } } })

hl.animation({ leaf = "global", enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "border", enabled = true, speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows", enabled = true, speed = 4.79, bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 4.1, bezier = "easeOutQuint", style = "popin 87%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 1.49, bezier = "linear", style = "popin 87%" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade", enabled = true, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers", enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 4, bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 1.5, bezier = "linear", style = "fade" })
hl.animation({ leaf = "fadeLayersIn", enabled = true, speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces", enabled = false, speed = 1, bezier = "default", style = "slide" })
hl.animation({ leaf = "workspacesIn", enabled = false, speed = 1, bezier = "default", style = "slide" })
hl.animation({ leaf = "workspacesOut", enabled = false, speed = 1, bezier = "default", style = "slide" })
hl.animation({ leaf = "zoomFactor", enabled = true, speed = 7, bezier = "quick" })

hl.device({
    name = "epic-mouse-v1",
    sensitivity = -0.5,
})

hl.on("hyprland.start", function()
    hl.exec_cmd("nm-applet --indicator")
    hl.exec_cmd(config_root .. "/waybar/scripts/launch.sh")
    hl.exec_cmd("eww daemon")
    hl.exec_cmd("waypaper --restore")
    hl.exec_cmd("hyprsunset")
end)

local function bind(keys, dispatcher, opts)
    hl.bind(keys, dispatcher, opts or {})
end

bind(mainMod .. " + Q", hl.dsp.exec_cmd(terminal))
bind(mainMod .. " + C", hl.dsp.window.close())
bind(mainMod .. " + M", hl.dsp.exec_cmd("uwsm stop"))
bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
bind(mainMod .. " + F", hl.dsp.window.fullscreen({ action = "toggle" }))
bind(mainMod .. " + R", hl.dsp.exec_cmd(menu))
bind(mainMod .. " + X", hl.dsp.exec_cmd(config_root .. "/rofi/scripts/control-center"))
bind(mainMod .. " + N", hl.dsp.exec_cmd(config_root .. "/rofi/scripts/control-network"))
bind(mainMod .. " + SHIFT + B", hl.dsp.exec_cmd(config_root .. "/rofi/scripts/control-bluetooth"))
bind(mainMod .. " + A", hl.dsp.exec_cmd(config_root .. "/rofi/scripts/control-audio"))
bind(mainMod .. " + P", hl.dsp.window.pseudo())
bind(mainMod .. " + Z", hl.dsp.exec_cmd(zed))
bind(mainMod .. " + B", hl.dsp.exec_cmd("brave"))
bind(mainMod .. " + W", hl.dsp.exec_cmd(config_root .. "/waybar/scripts/launch.sh"))
bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd("waypaper"))
bind(mainMod .. " + SHIFT + s", hl.dsp.exec_cmd(config_root .. "/rofi/scripts/control-screenshot"))

bind(mainMod .. " + h", hl.dsp.focus({ direction = "left" }))
bind(mainMod .. " + l", hl.dsp.focus({ direction = "right" }))
bind(mainMod .. " + k", hl.dsp.focus({ direction = "up" }))
bind(mainMod .. " + j", hl.dsp.focus({ direction = "down" }))

bind(mainMod .. " + SHIFT + h", hl.dsp.window.move({ direction = "left" }))
bind(mainMod .. " + SHIFT + l", hl.dsp.window.move({ direction = "right" }))
bind(mainMod .. " + SHIFT + k", hl.dsp.window.move({ direction = "up" }))
bind(mainMod .. " + SHIFT + j", hl.dsp.window.move({ direction = "down" }))

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
    bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = workspace }))
    bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = workspace }))
end

bind(mainMod .. " + Y", hl.dsp.workspace.toggle_special("magic"))
bind(mainMod .. " + SHIFT + Y", hl.dsp.window.move({ workspace = "special:magic" }))

bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd(config_root .. "/hypr/scripts/osdctl volume-up"), { locked = true, repeating = true })
bind("XF86AudioLowerVolume", hl.dsp.exec_cmd(config_root .. "/hypr/scripts/osdctl volume-down"), { locked = true, repeating = true })
bind("XF86AudioMute", hl.dsp.exec_cmd(config_root .. "/hypr/scripts/osdctl volume-mute"), { locked = true, repeating = true })
bind("XF86AudioMicMute", hl.dsp.exec_cmd(config_root .. "/hypr/scripts/osdctl mic-mute"), { locked = true, repeating = true })
bind("XF86MonBrightnessUp", hl.dsp.exec_cmd(config_root .. "/hypr/scripts/osdctl brightness-up"), { locked = true, repeating = true })
bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(config_root .. "/hypr/scripts/osdctl brightness-down"), { locked = true, repeating = true })

bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

for workspace = 1, 4 do
    hl.workspace_rule({
        workspace = tostring(workspace),
        monitor = "eDP-1",
        default = workspace == 1,
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
