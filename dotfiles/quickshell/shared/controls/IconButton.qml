import QtQuick

MouseArea {
    id: root

    required property var ui
    property string icon: ""
    property string label: ""
    property bool active: false
    property bool warning: false
    property bool critical: false
    property bool compact: true

    implicitWidth: compact ? 28 : Math.max(48, content.implicitWidth + 20)
    implicitHeight: 26
    width: implicitWidth
    height: implicitHeight
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor

    Rectangle {
        anchors.fill: parent
        radius: root.ui.geometry.buttonRadius
        color: root.containsMouse ? root.ui.surfaceHover : "transparent"
    }

    Row {
        id: content
        anchors.centerIn: parent
        spacing: 6

        Text {
            text: root.icon
            color: root.critical ? root.ui.critical : root.warning ? root.ui.warning : root.active ? root.ui.text : root.ui.textMuted
            font.family: root.ui.typography.iconFamily
            font.pixelSize: root.ui.typography.iconSize
            font.weight: Font.Bold
            verticalAlignment: Text.AlignVCenter
        }

        Text {
            visible: root.label.length > 0
            text: root.label
            color: root.ui.text
            font.family: root.ui.typography.bodyFamily
            font.pixelSize: root.ui.typography.bodySize
            font.weight: Font.Bold
            verticalAlignment: Text.AlignVCenter
        }
    }
}
