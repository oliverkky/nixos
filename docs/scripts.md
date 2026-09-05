# Desktop Command And Script Contract

`desktopctl` is the stable command-line interface between desktop callers and implementation scripts. Hyprland, Quickshell, keybindings, and interactive use should call `desktopctl`; systemd units may call private implementation scripts directly when they own that script's lifecycle.

## Command names

Structure:

```text
desktopctl <group> <command> [arguments...]
```

Examples:

```text
desktopctl audio volume-up
desktopctl display layout extend
desktopctl power profile set balanced
desktopctl wallpaper set /path/to/image.png
```

Use singular, lowercase, kebab-case group and command names. Prefer an existing group before adding another. Commands should describe user intent rather than the program used to implement it.

Run `desktopctl commands` to list the supported routes. A missing argument or unknown route exits with status 2. Runtime failures from an implementation command retain that command's exit status.

## Implementation scripts

Implementation scripts live beside the configuration they support and use lowercase kebab-case names. They are private interfaces unless exposed through `desktopctl`.

- `watch-*` is reserved for long-running event or polling loops owned by a systemd service.
- `apply-*` reconciles runtime state without changing the user's selected preference.
- `set-*` changes a preference and applies it.
- `*-info` and `state` operations are read-only.
- Interactive Rofi entry points retain the `control-*` prefix.

Scripts must use a shebang, enable strict error handling appropriate to their shell, write diagnostics to standard error, and return status 2 for invalid command-line usage. Dependencies belong in the script package's `runtimeInputs`; callers must not rely on ambient interactive-shell packages.

## Testing

`test/all` runs static validation and behavioral tests. Tests replace desktop programs with temporary command stubs, so they must not require Hyprland, Quickshell, PipeWire, or a graphical session.

New public routes need a dispatcher test. New non-trivial script behavior needs a focused test for its observable command calls, output, state, or exit status.
