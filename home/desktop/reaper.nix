{
  config,
  host,
  lib,
  pkgs,
  ...
}:

let
  pipewireLatency = host.reaper.pipewireLatency or "128/48000";
  lv2Path = "${config.home.profileDirectory}/lib/lv2";
  reaper = pkgs.callPackage ../../pkgs/reaper-pipewire-jack.nix { } {
    inherit lv2Path pipewireLatency;
  };
in
{
  options.my.home.desktop.reaper.enable = lib.mkEnableOption "REAPER user configuration";

  config = lib.mkIf config.my.home.desktop.reaper.enable {
    home.packages = [ reaper ];

    xdg.configFile."REAPER/libSwell-user.colortheme".text = ''
      default_font_face Liberation Sans
      default_font_size 13
      menubar_height 17
      menubar_font_size 12
      menubar_spacing_width 8
      menubar_margin_width 6
      scrollbar_width 14
      scrollbar_min_thumb_height 4
      combo_height 20

      _3dface #2B2F33
      _3dshadow #1E2226
      _3dhilight #3A3F44
      _3ddkshadow #111418

      button_bg #30353A
      button_text #E8EAED
      button_text_disabled #7D858C
      button_shadow #1C2024
      button_hilight #444A50

      checkbox_text #E8EAED
      checkbox_text_disabled #7D858C
      checkbox_fg #E8EAED
      checkbox_inter #444A50
      checkbox_bg #24282C

      scrollbar #1A1D20
      scrollbar_fg #6F7780
      scrollbar_bg #24282C

      edit_cursor #8AB4F8
      edit_bg #1F2327
      edit_bg_disabled #2B2F33
      edit_text #E8EAED
      edit_text_disabled #7D858C
      edit_bg_sel #315A86
      edit_text_sel #FFFFFF
      edit_hilight #3A3F44
      edit_shadow #16191C

      info_bk #25313A
      info_text #E8EAED

      menu_bg #25292D
      menu_shadow #16191C
      menu_hilight #3A3F44
      menu_text #E8EAED
      menu_text_disabled #7D858C
      menu_bg_sel #315A86
      menu_text_sel #FFFFFF
      menu_scroll #3A3F44
      menu_scroll_arrow #9AA0A6
      menu_submenu_arrow #C9CDD2

      menubar_bg #25292D
      menubar_text #E8EAED
      menubar_text_disabled #7D858C
      menubar_bg_sel #315A86
      menubar_text_sel #FFFFFF

      trackbar_track #1E2226
      trackbar_mark #6F7780
      trackbar_knob #C9CDD2
      progress #8AB4F8

      label_text #E8EAED
      label_text_disabled #7D858C
      combo_text #E8EAED
      combo_text_disabled #7D858C
      combo_bg #30353A
      combo_bg2 #25292D
      combo_shadow #1C2024
      combo_hilight #444A50
      combo_arrow #C9CDD2
      combo_arrow_press #FFFFFF

      listview_bg #1F2327
      listview_bg_sel #315A86
      listview_text #E8EAED
      listview_text_sel #FFFFFF
      listview_bg_sel_inactive #30353A
      listview_text_sel_inactive #E8EAED
      listview_grid #30353A
      listview_hdr_arrow #C9CDD2
      listview_hdr_shadow #1C2024
      listview_hdr_hilight #444A50
      listview_hdr_bg #2B2F33
      listview_hdr_text #E8EAED

      treeview_text #E8EAED
      treeview_bg #1F2327
      treeview_bg_sel #315A86
      treeview_text_sel #FFFFFF
      treeview_bg_sel_inactive #30353A
      treeview_text_sel_inactive #E8EAED
      treeview_arrow #C9CDD2

      tab_shadow #1C2024
      tab_hilight #444A50
      tab_text #E8EAED
      focusrect #8AB4F8
      group_text #E8EAED
      group_shadow #1C2024
      group_hilight #444A50
      focus_hilight #3A3F44
    '';
  };
}
