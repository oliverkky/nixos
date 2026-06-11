import QtQuick
import Quickshell
import Quickshell as QS
import Quickshell.Wayland

QS.PanelWindow {
    id: root

    property int barHeight: 32

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
            radius: 10
        }

        Region {
            item: clock
            radius: clock.height / 2
        }

        Region {
            item: statusArea
            radius: statusArea.height / 2
        }
    }

    ColorScheme {
        id: colorScheme
    }

    Item {
        anchors.fill: parent

        Workspaces {
            id: workspaces

            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            ui: colorScheme
        }

        Clock {
            id: clock

            anchors.centerIn: parent
            ui: colorScheme
            parentWindow: root
        }

        StatusArea {
            id: statusArea

            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            ui: colorScheme
            parentWindow: root
        }
    }
}
