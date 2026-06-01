import QtQuick
import Quickshell as QS

QS.PopupWindow {
    id: root

    required property var ui
    default property alias content: content.data

    color: "transparent"
    grabFocus: true

    Rectangle {
        anchors.fill: parent
        radius: 16
        color: root.ui.panelSurface
        border.width: 1
        border.color: root.ui.border

        Item {
            id: content
            anchors.fill: parent
            anchors.margins: 12
        }
    }
}
