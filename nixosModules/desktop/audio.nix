{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.my.nixos.desktop.audio.enable =
    lib.mkEnableOption "desktop audio and Wayland runtime libraries";

  options.my.nixos.desktop.audio.production.enable =
    lib.mkEnableOption "low-latency PipeWire/JACK tuning for audio production";

  config = lib.mkIf config.my.nixos.desktop.audio.enable {
    # ── Graphics & Wayland libs ───────────────────────────────────────────────
    # Use nix-ld instead of a global LD_LIBRARY_PATH.
    # This lets dynamically-linked binaries find system libs without poisoning
    # every process's linker search path.

    programs.nix-ld = {
      enable = true;
      libraries = with pkgs; [
        wayland
        libxkbcommon
        mesa
        libGL
        vulkan-loader
      ];
    };

    # ── Sound ─────────────────────────────────────────────────────────────────

    boot.kernelParams = lib.mkIf config.my.nixos.desktop.audio.production.enable [
      "threadirqs"
    ];

    services.pulseaudio.enable = false;
    security.rtkit.enable = true;

    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      jack.enable = true;
      pulse.enable = true;

      extraConfig.pipewire = lib.mkIf config.my.nixos.desktop.audio.production.enable {
        "92-low-latency" = {
          "context.properties" = {
            "default.clock.rate" = 48000;
            "default.clock.allowed-rates" = [
              44100
              48000
              88200
              96000
            ];
            "default.clock.quantum" = 128;
            "default.clock.min-quantum" = 32;
            "default.clock.max-quantum" = 1024;
            "loop.rt-prio" = 88;
            "mem.allow-mlock" = true;
            "mem.warn-mlock" = false;
          };
        };
      };
    };

    security.pam.loginLimits = lib.mkIf config.my.nixos.desktop.audio.production.enable [
      {
        domain = "@audio";
        type = "-";
        item = "rtprio";
        value = 95;
      }
      {
        domain = "@audio";
        type = "-";
        item = "memlock";
        value = "unlimited";
      }
      {
        domain = "@audio";
        type = "-";
        item = "nice";
        value = -19;
      }
    ];
  };
}
