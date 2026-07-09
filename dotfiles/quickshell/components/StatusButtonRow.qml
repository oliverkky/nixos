import QtQuick
import "." as Components

Row {
    id: root

    required property var ui
    property string bluetoothIcon: ""
    property bool bluetoothActive: false
    property string networkIcon: ""
    property bool networkActive: false
    property string volumeIcon: ""
    property bool volumeActive: false
    property bool hasBattery: false
    property string batteryIcon: ""
    property real batteryPercent: 0
    property bool batteryWarning: false
    property bool batteryCritical: false
    property bool idleInhibited: false
    property bool contextActionsEnabled: false

    signal bluetoothClicked(var mouse)
    signal networkClicked(var mouse)
    signal volumeClicked(var mouse)
    signal batteryClicked(var mouse)
    signal idleClicked(var mouse)
    signal powerClicked(var mouse)

    spacing: 2

    Components.IconButton {
        ui: root.ui
        icon: root.bluetoothIcon
        active: root.bluetoothActive
        acceptedButtons: root.contextActionsEnabled ? Qt.LeftButton | Qt.RightButton : Qt.LeftButton
        onClicked: mouse => root.bluetoothClicked(mouse)
    }

    Components.IconButton {
        ui: root.ui
        icon: root.networkIcon
        active: root.networkActive
        acceptedButtons: root.contextActionsEnabled ? Qt.LeftButton | Qt.RightButton : Qt.LeftButton
        onClicked: mouse => root.networkClicked(mouse)
    }

    Components.IconButton {
        ui: root.ui
        icon: root.volumeIcon
        active: root.volumeActive
        acceptedButtons: root.contextActionsEnabled ? Qt.LeftButton | Qt.RightButton : Qt.LeftButton
        onClicked: mouse => root.volumeClicked(mouse)
    }

    Components.IconButton {
        visible: root.hasBattery
        ui: root.ui
        icon: root.batteryIcon
        label: root.hasBattery ? `${Math.round(root.batteryPercent)}%` : ""
        active: true
        warning: root.batteryWarning
        critical: root.batteryCritical
        compact: false
        onClicked: mouse => root.batteryClicked(mouse)
    }

    Components.IconButton {
        visible: root.idleInhibited
        ui: root.ui
        icon: "󰅶"
        active: root.idleInhibited
        onClicked: mouse => root.idleClicked(mouse)
    }

    Components.IconButton {
        ui: root.ui
        icon: ""
        active: true
        onClicked: mouse => root.powerClicked(mouse)
    }
}
