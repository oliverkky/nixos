-- Hyprland 0.55+ Lua config.

local home = os.getenv("HOME") or "/home/oliver"
local config_root = os.getenv("XDG_CONFIG_HOME") or (home .. "/.config")
local module_root = config_root .. "/hypr/lua"

local ctx = {
    home = home,
    config_root = config_root,
    terminal = "kitty",
    file_manager = "nautilus",
    menu = "rofi -show drun",
    zed = "zeditor",
    main_mod = "SUPER",
    primary_monitor = os.getenv("HYPR_PRIMARY_MONITOR") or "",
}

local function load_module(name)
    return dofile(module_root .. "/" .. name .. ".lua")(ctx)
end

ctx.wal = load_module("theme")

load_module("settings")
load_module("animations")
load_module("autostart")
load_module("binds")
load_module("gestures")
load_module("rules")
