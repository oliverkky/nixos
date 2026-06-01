import QtQuick
import Quickshell as QS

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

    ColorScheme {
        id: colorScheme
    }

    Item {
        anchors.fill: parent

        Workspaces {
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            ui: colorScheme
        }

        Clock {
            anchors.centerIn: parent
            ui: colorScheme
            parentWindow: root
        }

        StatusArea {
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            ui: colorScheme
            parentWindow: root
        }
    }
}
