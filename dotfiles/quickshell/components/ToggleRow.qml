import QtQuick

Item {
    id: root

    required property var ui
    property string icon: ""
    property string iconFont: "JetBrainsMonoNL Nerd Font"
    property string label: ""
    property bool checked: false
    property bool highlighted: false
    signal toggled(bool checked)

    width: 122
    height: 28

    Rectangle {
        anchors.fill: parent
        radius: 8
        color: root.highlighted ? root.ui.surfaceHover : "transparent"
        border.width: root.highlighted ? 1 : 0
        border.color: root.ui.accent
    }

    Row {
        anchors.fill: parent
        spacing: 7

        Text {
            width: 16
            anchors.verticalCenter: parent.verticalCenter
            text: root.icon
            color: root.checked ? root.ui.text : root.ui.textMuted
            font.family: root.iconFont
            font.pixelSize: 14
        }

        Text {
            width: 62
            anchors.verticalCenter: parent.verticalCenter
            text: root.label
            color: root.ui.text
            font.family: "Cantarell"
            font.pixelSize: 11
        }

        Rectangle {
            width: 28
            height: 16
            anchors.verticalCenter: parent.verticalCenter
            radius: height / 2
            color: root.checked ? root.ui.accent : root.ui.surface

            Rectangle {
                width: 12
                height: 12
                anchors.verticalCenter: parent.verticalCenter
                x: root.checked ? parent.width - width - 2 : 2
                radius: width / 2
                color: root.checked ? root.ui.background : root.ui.textMuted

                Behavior on x {
                    NumberAnimation { duration: 120 }
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled(!root.checked)
    }
}
