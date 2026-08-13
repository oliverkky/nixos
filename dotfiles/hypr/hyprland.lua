-- Hyprland 0.55+ Lua config.

local user = os.getenv("USER")
local home = os.getenv("HOME") or (user and ("/home/" .. user) or ".")
local config_root = os.getenv("XDG_CONFIG_HOME") or (home .. "/.config")
local module_root = config_root .. "/hypr/lua"
local hypr_script_dir = os.getenv("HYPR_SCRIPT_DIR") or (config_root .. "/hypr/scripts")
local rofi_script_dir = os.getenv("ROFI_SCRIPT_DIR") or (config_root .. "/rofi/scripts")

local ctx = {
    home = home,
    config_root = config_root,
    terminal = "kitty",
    file_manager = "nautilus",
    menu = rofi_script_dir .. "/launcher",
    zed = "zeditor",
    main_mod = "SUPER",
    hypr_script_dir = hypr_script_dir,
    rofi_script_dir = rofi_script_dir,
    cursor_size = tonumber(os.getenv("XCURSOR_SIZE") or "") or 24,
    monitors = os.getenv("HYPR_MONITORS") or "",
    monitor_hdrs = os.getenv("HYPR_MONITOR_HDRS") or "",
    primary_monitor = os.getenv("HYPR_PRIMARY_MONITOR") or "",
    primary_monitor_scale = tonumber(os.getenv("HYPR_PRIMARY_MONITOR_SCALE") or "") or 1,
    secondary_monitor = os.getenv("HYPR_SECONDARY_MONITOR") or "",
    secondary_monitor_workspace = tonumber(os.getenv("HYPR_SECONDARY_MONITOR_WORKSPACE") or ""),
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
