import QtQuick
import Quickshell
import Quickshell as QS
import Quickshell.Wayland

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

    ColorScheme {
        id: colorScheme
    }

    Connections {
        target: root.shellRoot

        function onOpenSystemMenu() {
            statusArea.openPowerMenu();
        }

        function onToggleStatusPanel(panelName) {
            statusArea.togglePanel(panelName);
        }

    }

    Item {
        anchors.fill: parent

        Workspaces {
            id: workspaces

            anchors.left: parent.left
            anchors.leftMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            ui: colorScheme
        }

        Clock {
            id: clock

            anchors.centerIn: parent
            ui: colorScheme
            parentWindow: root
        }

        PrivacyIndicator {
            id: privacyIndicator

            anchors.left: clock.right
            anchors.leftMargin: 7
            anchors.verticalCenter: clock.verticalCenter
            ui: colorScheme
        }

        StatusArea {
            id: statusArea

            anchors.right: parent.right
            anchors.rightMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            ui: colorScheme
            parentWindow: root
        }

    }
}
