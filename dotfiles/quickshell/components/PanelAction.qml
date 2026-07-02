import QtQuick

MouseArea {
    id: root

    required property var ui
    property string icon: ""
    property string text: ""
    property string subtext: ""
    property bool active: false
    property bool selected: false
    property bool warning: false
    property bool danger: false
    property string trailingIcon: ""
    property string trailingText: ""
    property bool trailingWarning: false
    property bool trailingCritical: false
    readonly property bool hasTrailing: trailingIcon.length > 0 || trailingText.length > 0

    implicitHeight: 34
    height: implicitHeight
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor

    Rectangle {
        anchors.fill: parent
        radius: 8
        color: root.containsMouse || root.active || root.selected ? root.ui.surfaceHover : "transparent"
        border.width: root.active || root.selected ? 1 : 0
        border.color: root.ui.borderSoft
    }

    Row {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 10

        Text {
            width: 18
            anchors.verticalCenter: parent.verticalCenter
            text: root.icon
            color: root.danger ? root.ui.critical : root.warning ? root.ui.warning : root.ui.text
            font.family: "Symbols Nerd Font"
            font.pixelSize: 14
            font.weight: Font.Bold
            horizontalAlignment: Text.AlignHCenter
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: Math.max(0, parent.width
                - 18
                - (trailingValue.visible ? trailingValue.implicitWidth : 0)
                - (trailingValue.visible ? 20 : 10))
            spacing: 1

            Text {
                width: parent.width
                text: root.text
                color: root.danger ? root.ui.critical : root.warning ? root.ui.warning : root.ui.text
                elide: Text.ElideRight
                font.family: "Cantarell"
                font.pixelSize: 12
                font.weight: Font.Bold
            }

            Text {
                visible: root.subtext.length > 0
                width: parent.width
                text: root.subtext
                color: root.ui.textMuted
                elide: Text.ElideRight
                font.family: "Cantarell"
                font.pixelSize: 11
            }
        }

        Row {
            id: trailingValue

            visible: root.hasTrailing
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4

            Text {
                visible: root.trailingIcon.length > 0
                text: root.trailingIcon
                color: root.trailingCritical ? root.ui.critical : root.trailingWarning ? root.ui.warning : root.ui.textMuted
                font.family: "Symbols Nerd Font"
                font.pixelSize: 13
                font.weight: Font.Bold
            }

            Text {
                visible: root.trailingText.length > 0
                text: root.trailingText
                color: root.trailingCritical ? root.ui.critical : root.trailingWarning ? root.ui.warning : root.ui.textMuted
                font.family: "Cantarell"
                font.pixelSize: 11
                font.weight: Font.Bold
            }
        }
    }
}
