# PipeWire/JACK Audio Workflow

This system uses PipeWire as the single audio server:

- normal desktop apps use the PipeWire PulseAudio server
- ALSA apps are routed through PipeWire
- JACK apps use PipeWire's JACK compatibility layer

That means `qjackctl` is no longer the service controller. PipeWire is started by the user session, and `qpwgraph` is the patchbay for wiring applications and hardware ports.

## NixOS switches

Basic desktop audio is enabled by:

```nix
my.nixos.desktop.audio.enable = true;
```

Audio-production tuning is enabled separately:

```nix
my.nixos.desktop.audio.production.enable = true;
```

The production switch adds realtime limits for the `audio` group and sets PipeWire's default clock to 48 kHz with a 128-frame quantum. The effective round-trip latency still depends on the audio interface, plugin load, sample rate, and whether the app requests a different buffer size.

Production mode also enables `threadirqs` and asks PipeWire to run its data loop with realtime priority. This helps scheduling, but it does not guarantee tiny buffers on every interface.

REAPER is wrapped by Home Manager with:

```nix
host.reaper.pipewireLatency = "128/48000";
```

That value is passed as `PIPEWIRE_LATENCY`, so REAPER asks PipeWire/JACK for a 128-frame buffer at 48 kHz. Use `"64/48000"` for an aggressive test, or `"256/48000"` / `"512/48000"` if a project needs a safer buffer.

VCV Rack is also wrapped with `pw-jack`. Its latency defaults to `host.vcvRack.pipewireLatency`, then `host.reaper.pipewireLatency`, then `"128/48000"`.

Home Manager also writes `~/.config/REAPER/libSwell-user.colortheme`. This makes REAPER's native Linux menus and utility windows use dark SWELL colors without forcing a global GTK theme.

## REAPER

In REAPER, use:

- audio system: `JACK`
- sample rate: usually `48000`
- block size: start at `128`, increase to `256` or `512` if you hear crackles

When REAPER is running, open `qpwgraph` and connect:

- hardware capture ports to REAPER inputs
- REAPER outputs to hardware playback ports
- Discord/desktop app streams only where needed

## VCV Rack

In VCV Rack, use:

- audio driver: `JACK`
- device: usually `system` / PipeWire JACK ports
- sample rate: usually `48000`

When Rack is running, use `qpwgraph` to connect Rack's audio and MIDI ports to hardware or other JACK/PipeWire applications.

## Discord and desktop apps

Discord should stay on its normal PulseAudio/PipeWire path. Use `pavucontrol` or the shell audio panel for basic device selection, and use `qpwgraph` only when you need explicit routing.

For Discord monitoring or streaming from the DAW, create the route in `qpwgraph` from the DAW output or monitor source to Discord's input stream. Avoid making persistent graph changes until the temporary routing works reliably.

## Useful checks

```sh
pw-top
pw-cli info 0
wpctl status
systemctl --user status pipewire pipewire-pulse wireplumber
```

If audio crackles, first raise the DAW block size. If the whole desktop becomes unstable, disable the production switch and rebuild.
