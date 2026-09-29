import QtQuick
import Quickshell
import Quickshell as QS
import Quickshell.Wayland
import "../../shared/theme" as Theme
import "../status" as Status

QS.PanelWindow {
    id: root

    required property var shellRoot
    property int barHeight: 36

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: barHeight
    exclusiveZone: barHeight
    aboveWindows: true
    color: "transparent"

    WlrLayershell.namespace: "oliver.quickshell"

    BackgroundEffect.blurRegion: Region {
        Region {
            item: workspaces
            radius: workspaces.height / 2
        }

        Region {
            item: clock
            radius: clock.height / 2
        }

        Region {
            item: privacyIndicator
            radius: privacyIndicator.height / 2
        }

        Region {
            item: statusArea
            radius: statusArea.height / 2
        }
    }

    Theme.Theme {
        id: theme
    }

    Connections {
        target: root.shellRoot

        function onOpenSystemMenu() {
            statusArea.openPowerMenu();
        }

        function onToggleStatusPanel(panelName) {
            statusArea.togglePanel(panelName);
        }

        function onOpenCalendarMedia() {
            clock.openPopover();
        }

    }

    Item {
        anchors.fill: parent

        Workspaces {
            id: workspaces

            anchors.left: parent.left
            anchors.leftMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            ui: theme
        }

        Clock {
            id: clock

            anchors.centerIn: parent
            ui: theme
            parentWindow: root
        }

        PrivacyIndicator {
            id: privacyIndicator

            anchors.left: clock.right
            anchors.leftMargin: 6
            anchors.verticalCenter: clock.verticalCenter
            ui: theme
        }

        Status.StatusArea {
            id: statusArea

            anchors.right: parent.right
            anchors.rightMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            ui: theme
            parentWindow: root
        }

    }
}
