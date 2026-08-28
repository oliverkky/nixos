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

      _3dface #303030
      _3dshadow #1B1B1B
      _3dhilight #4A4A4A
      _3ddkshadow #101010

      button_bg #353535
      button_text #E2E2E2
      button_text_disabled #777777
      button_shadow #1A1A1A
      button_hilight #646464

      checkbox_text #E2E2E2
      checkbox_text_disabled #777777
      checkbox_fg #E2E2E2
      checkbox_inter #5A5A5A
      checkbox_bg #242424

      scrollbar #181818
      scrollbar_fg #6A6A6A
      scrollbar_bg #292929

      edit_cursor #C8C8C8
      edit_bg #202020
      edit_bg_disabled #2B2B2B
      edit_text #E2E2E2
      edit_text_disabled #777777
      edit_bg_sel #555555
      edit_text_sel #FFFFFF
      edit_hilight #494949
      edit_shadow #161616

      info_bk #2B2B2B
      info_text #E2E2E2

      menu_bg #282828
      menu_shadow #161616
      menu_hilight #4A4A4A
      menu_text #E2E2E2
      menu_text_disabled #777777
      menu_bg_sel #555555
      menu_text_sel #FFFFFF
      menu_scroll #4A4A4A
      menu_scroll_arrow #A0A0A0
      menu_submenu_arrow #C8C8C8

      menubar_bg #282828
      menubar_text #E2E2E2
      menubar_text_disabled #777777
      menubar_bg_sel #555555
      menubar_text_sel #FFFFFF

      trackbar_track #1E1E1E
      trackbar_mark #6A6A6A
      trackbar_knob #BEBEBE
      progress #BEBEBE

      label_text #E2E2E2
      label_text_disabled #777777
      combo_text #E2E2E2
      combo_text_disabled #777777
      combo_bg #353535
      combo_bg2 #282828
      combo_shadow #1A1A1A
      combo_hilight #646464
      combo_arrow #C8C8C8
      combo_arrow_press #FFFFFF

      listview_bg #202020
      listview_bg_sel #5A5A5A
      listview_text #E2E2E2
      listview_text_sel #FFFFFF
      listview_bg_sel_inactive #383838
      listview_text_sel_inactive #E2E2E2
      listview_grid #363636
      listview_hdr_arrow #C8C8C8
      listview_hdr_shadow #1A1A1A
      listview_hdr_hilight #646464
      listview_hdr_bg #303030
      listview_hdr_text #E2E2E2

      # REAPER's FX browser uses the generic list colors for its main pane.
      genlist_bg #202020
      genlist_fg #E2E2E2
      genlist_selbg #5A5A5A
      genlist_selfg #FFFFFF

      treeview_text #E2E2E2
      treeview_bg #202020
      treeview_bg_sel #5A5A5A
      treeview_text_sel #FFFFFF
      treeview_bg_sel_inactive #383838
      treeview_text_sel_inactive #E2E2E2
      treeview_arrow #C8C8C8

      tab_shadow #1A1A1A
      tab_hilight #646464
      tab_text #E2E2E2
      focusrect #BEBEBE
      group_text #E2E2E2
      group_shadow #1A1A1A
      group_hilight #646464
      focus_hilight #4A4A4A
    '';
  };
}
