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
            width: parent.width * root.normalizedValue()
            height: parent.height
            radius: parent.radius
            color: root.ui.surfaceStrong
        }

        MouseArea {
            id: sliderMouse

            anchors.fill: parent
            anchors.margins: -8
            cursorShape: Qt.PointingHandCursor
            onPressed: mouse => root.moved(root.valueForMouse(mouse))
            onPositionChanged: mouse => {
                if (sliderMouse.pressed)
                    root.moved(root.valueForMouse(mouse));
            }
        }
    }

    function valueForMouse(mouse) {
        const position = track.mapFromItem(sliderMouse, mouse.x, mouse.y).x;
        return Math.max(0, Math.min(root.maximum, root.maximum * position / track.width));
    }

    function normalizedValue() {
        if (root.maximum <= 0)
            return 0;
        return Math.max(0, Math.min(1, root.value / root.maximum));
    }
}
