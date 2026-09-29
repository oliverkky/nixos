import QtQuick
import Quickshell
import Quickshell as QS
import Quickshell.Hyprland
import Quickshell.Wayland
import "../../shared/theme" as Theme

QS.PanelWindow {
    id: root

    required property var shellRoot
    readonly property bool isActiveScreen: {
        if (Hyprland.focusedMonitor)
            return root.screen && root.screen.name === Hyprland.focusedMonitor.name;

        return Quickshell.screens.length > 0 && root.screen === Quickshell.screens[0];
    }

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: 1
    exclusiveZone: 0
    aboveWindows: true
    focusable: false
    color: "transparent"
    mask: Region {}

    WlrLayershell.namespace: "oliver.quickshell.display-anchor"

    Theme.Theme {
        id: colorScheme
    }

    Connections {
        target: root.shellRoot

        function onOpenDisplayLayout() {
            if (root.isActiveScreen)
                displayPopover.openLayout();
        }

        function onOpenDisplayCurrent() {
            if (root.isActiveScreen)
                displayPopover.openCurrent();
        }
    }

    DisplayPopover {
        id: displayPopover

        ui: colorScheme
        parentWindow: root
    }
}
