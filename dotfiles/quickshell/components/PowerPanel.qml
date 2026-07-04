import QtQuick

Column {
    id: root

    required property var ui
    required property var actions
    property int selectedIndex: 0
    signal entered(int index)
    signal runAction(int index)

    spacing: 6

    Repeater {
        model: root.actions

        PanelAction {
            required property int index
            required property var modelData

            width: parent.width
            ui: root.ui
            icon: modelData.icon
            text: modelData.text
            danger: modelData.danger || false
            selected: root.selectedIndex === index
            onEntered: root.entered(index)
            onClicked: root.runAction(index)
        }
    }
}
