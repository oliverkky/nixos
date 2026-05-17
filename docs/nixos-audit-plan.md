# NixOS Audit Plan

Context: this setup is intended to become an unbreakable, uniform NixOS desktop platform across machines, starting with the laptop. The current priority is correctness, reliability, security, and maintainability before deeper gaming/audio layers.

Note on Hyprland: keep the Hyprland 0.55 GitHub flake pin for now to continue testing the new Lua-based config. After Hyprland 0.55 reaches nixpkgs, switch back to the nixpkgs package unless there is a concrete reason to keep tracking upstream.

## Do First

1. Add idle and suspend locking. Done.
   - This is the best first fix because it is narrow, low-risk, and closes a real laptop security gap immediately.
   - Added `hypridle`.
   - Locks before suspend.
   - Locks after a short idle period.
   - Turns displays off after a longer idle period.
   - Laptop lid behavior is explicit.

2. Add a Polkit agent. Done.
   - This is also low-risk and prevents confusing GUI privilege failures.
   - Added a lightweight agent supervised through systemd user services.

3. Consolidate daemon supervision. Done.
   - Move long-running desktop daemons toward systemd user services.
   - Keep Hyprland autostart for compositor-specific one-shot setup only.
   - Moved Waybar, nm-applet, eww, hyprsunset, awww-daemon, wallpaper restore, and the power-profile display watcher to systemd user services.

4. Fix wallpaper config duplication. Done.
   - Pick one canonical Waypaper config.
   - Pick one backend.
   - Scripts and config now agree on the `awww` backend and the top-level Waypaper config is canonical.

5. Move host-specific display data out of shared config. Done.
   - Keep `eDP-1` details in the laptop host layer.
   - The laptop host sets `my.host.primaryMonitor = "eDP-1"`.
   - The Hyprland module generates `HYPR_PRIMARY_MONITOR` from that typed option.
   - Home Manager generates Waybar configs with `output` set to the typed primary monitor.

After those are done, handle update discipline and security posture: kernel choice, trusted Nix user, input group, disk encryption plan, and recovery process.

## Current Verification

- `nix flake check --no-build` passed.
- `nix eval .#nixosConfigurations.laptop1.config.system.build.toplevel.drvPath` passed.
- `nix build .#nixosConfigurations.laptop1.config.system.build.toplevel --dry-run` passed after allowing Nix cache access.
- The repo is dirty, so the current state is not a clean reproducible checkpoint.

## Highest Priority Findings

1. Update strategy is too close to nightly for the stated goal.
   - `flake.nix` uses `nixos-unstable`, which is acceptable for "new but not beta".
   - `boot.kernelPackages = pkgs.linuxPackages_latest` is riskier than necessary.
   - Hyprland is intentionally pulled from GitHub for now to test 0.55 Lua config.
   - Action: keep Hyprland upstream temporarily, but later switch back to nixpkgs once 0.55 lands. Consider using the regular nixpkgs kernel unless the latest kernel is needed for hardware support.

2. There is no idle locking.
   - `hyprlock` is installed, but there is no `hypridle`, swayidle, systemd sleep hook, or lid/suspend lock integration.
   - Manual lock is not enough for a laptop.
   - Done: added `hypridle` with lock-before-suspend, lock-on-idle, display-off timers, and explicit laptop lid behavior.

3. No disk encryption is visible.
   - The laptop mounts plain ext4 by UUID and has no `boot.initrd.luks.devices`.
   - For a portable laptop, this is a major security gap.
   - Action: plan full disk encryption for this laptop or next reinstall.

4. `oliver` is a trusted Nix user.
   - `trusted-users = [ "root" "oliver" ];` is effectively root-equivalent in Nix terms.
   - It is convenient, but not hardened.
   - Action: decide whether convenience is worth the security tradeoff.

5. User is in the `input` group.
   - Direct input-device access broadens keylogging/input access.
   - Action: prefer udev/logind-based access if possible, or document why this is required.

6. No Polkit agent is configured.
   - GUI privilege prompts may randomly fail or do nothing.
   - Done: added `polkit_gnome` and a systemd user service for it.

7. GNOME-style toggles are partially fake.
   - Waybar scripts toggle `org.gnome.settings-daemon.plugins.color night-light-enabled`, but GNOME Settings Daemon is not running.
   - `hyprsunset` is autostarted separately.
   - Action: make quick settings reflect actual Hyprland/Hyprsunset state instead of GNOME-only state.

8. Monitor identity is hard-coded everywhere.
   - Hyprland, Waybar, and power-profile display scripts assume `eDP-1`.
   - This is okay for the laptop, bad for uniform multi-machine config.
   - Done: the laptop host sets `my.host.primaryMonitor = "eDP-1"`, the Hyprland module generates `HYPR_PRIMARY_MONITOR`, and Home Manager generates Waybar configs targeted to that primary monitor.

9. Wallpaper config is duplicated and inconsistent.
   - Previous state: Home Manager linked one Waypaper config, while Hyprland had another nested Waypaper config and scripts forced a different backend.
   - Done: top-level `dotfiles/waypaper` is canonical, uses `awww`, and includes the stylesheet.

10. Desktop daemons are split awkwardly.
    - Mako, cliphist, wl-clip-persist, and gestures are systemd user services.
    - Waybar, nm-applet, eww, wallpaper restore, power profile watcher, and hyprsunset are Hyprland autostart.
    - Done: long-running desktop daemons are now systemd user services, including the wallpaper daemon.

## Missing For A Strong Daily Driver

- Add `fwupd`.
- Add `fstrim`.
- Add battery charge thresholds if the laptop supports them.
- Add `thermald` or vendor-specific power tooling if appropriate.
- Add zram.
- Add SMART/disk health monitoring.
- Add a real backup plan.
- Add lid behavior.
- Add suspend behavior.
- Add idle lock behavior.
- Add screenshot directory policy.
- Add secrets handling.
- Add recovery documentation.

## Development Direction

- Current global Rust and Python toolchains are acceptable early on.
- Over time, move language toolchains into per-project `devShell`s or `direnv`.
- Keep global packages for editors, Nix tooling, and essential rescue tools.

## Audio Production Direction

- PipeWire + RTKit is the correct base.
- Later add JACK support and low-latency PipeWire tuning.
- Later add Reaper, VCV Rack, MuseScore, Wine/Yabridge, and plugin isolation.
- Consider a separate audio-production module/profile instead of mixing this into the minimal desktop base.

## Gaming Direction

- Add Steam only when ready.
- Use `programs.steam.enable`.
- Ensure 32-bit graphics support.
- Add MangoHud, Gamemode, controller support, and Proton tooling.
- Keep gaming as an optional module/profile, not part of the minimal desktop base.

## Good Existing Decisions

- Module split is clean.
- Home Manager is used appropriately.
- Firewall is explicitly enabled.
- PipeWire is the right default.
- The visual stack is coherent and close to the intended taste.
- The setup evaluates cleanly.

## Summary

The current config is promising, but it is currently custom laptop rice that evaluates, not yet an unbreakable uniform platform. First fix locking, disk/security posture, update discipline, host abstraction, and daemon supervision. Then polish visuals and add gaming/audio layers.
