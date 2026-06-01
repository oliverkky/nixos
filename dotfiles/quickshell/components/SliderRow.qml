import QtQuick

Row {
    id: root

    required property var ui
    property string icon: ""
    property real value: 0
    property real maximum: 1
    signal moved(real value)

    height: 34
    spacing: 10

    Text {
        width: 18
        anchors.verticalCenter: parent.verticalCenter
        text: root.icon
        color: root.ui.text
        font.family: "Symbols Nerd Font"
        font.pixelSize: 14
        font.weight: Font.Bold
        horizontalAlignment: Text.AlignHCenter
    }

    Rectangle {
        id: track
        width: parent.width - 28
        height: 8
        anchors.verticalCenter: parent.verticalCenter
        radius: 999
        color: root.ui.surface

        Rectangle {
            width: Math.max(8, Math.min(parent.width, parent.width * (root.value / root.maximum)))
            height: parent.height
            radius: parent.radius
            color: root.ui.surfaceStrong
        }

        MouseArea {
            anchors.fill: parent
            anchors.margins: -8
            cursorShape: Qt.PointingHandCursor
            onPressed: mouse => root.moved(Math.max(0, Math.min(root.maximum, root.maximum * mouse.x / track.width)))
            onPositionChanged: mouse => {
                if (pressed)
                    root.moved(Math.max(0, Math.min(root.maximum, root.maximum * mouse.x / track.width)));
            }
        }
    }
}
