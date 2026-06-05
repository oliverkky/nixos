{
  config,
  host,
  lib,
  pkgs,
  ...
}:

let
  uiScale = host.reaper.uiScale or null;
in
{
  options.my.home.desktop.reaper.enable = lib.mkEnableOption "REAPER user configuration";

  config = lib.mkIf (config.my.home.desktop.reaper.enable && uiScale != null) {
    home.activation.reaperUiScale = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      config_file="${config.xdg.configHome}/REAPER/reaper.ini"
      mkdir -p "$(dirname "$config_file")"
      touch "$config_file"

      tmp="$(${pkgs.coreutils}/bin/mktemp)"
      ${pkgs.gawk}/bin/awk -v scale="${toString uiScale}" '
        function emit_missing() {
          if (in_swell) {
            if (!wrote_auto) {
              print "ui_scale_auto=0"
            }
            if (!wrote_scale) {
              print "ui_scale=" scale
            }
          }
        }

        /^\[/ {
          emit_missing()
          in_swell = ($0 == "[.swell]")
          if (in_swell) {
            saw_swell = 1
            wrote_auto = 0
            wrote_scale = 0
          }
          print
          next
        }

        in_swell && /^ui_scale_auto=/ {
          print "ui_scale_auto=0"
          wrote_auto = 1
          next
        }

        in_swell && /^ui_scale=/ {
          print "ui_scale=" scale
          wrote_scale = 1
          next
        }

        { print }

        END {
          emit_missing()
          if (!saw_swell) {
            print "[.swell]"
            print "ui_scale_auto=0"
            print "ui_scale=" scale
          }
        }
      ' "$config_file" > "$tmp"
      ${pkgs.coreutils}/bin/mv "$tmp" "$config_file"
    '';
  };
}
