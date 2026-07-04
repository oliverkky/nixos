import QtQuick
import Quickshell.Bluetooth

Column {
    id: root

    required property var ui
    property var adapter: null
    required property var devices
    required property var batteryLabel
    required property var batteryAvailable
    required property var batteryIcon
    required property var batteryPercent
    required property var batteryPercentLabel

    signal openFallback

    width: parent.width
    height: parent.height
    spacing: 8

    Row {
        id: bluetoothHeader

        width: parent.width
        height: 30

        Text {
            width: parent.width - 110
            anchors.verticalCenter: parent.verticalCenter
            text: root.adapter ? root.adapter.name : "Bluetooth"
            color: root.ui.text
            elide: Text.ElideRight
            font.family: "Cantarell"
            font.pixelSize: 13
            font.weight: Font.Bold
        }

        IconButton {
            ui: root.ui
            icon: root.adapter && root.adapter.enabled ? "󰂯" : "󰂲"
            label: root.adapter && root.adapter.enabled ? "On" : "Off"
            active: root.adapter && root.adapter.enabled
            compact: false
            onClicked: if (root.adapter)
                root.adapter.enabled = !root.adapter.enabled
        }

        IconButton {
            ui: root.ui
            icon: "󰑓"
            active: root.adapter && root.adapter.discovering
            onClicked: if (root.adapter)
                root.adapter.discovering = !root.adapter.discovering
        }
    }

    Rectangle {
        id: bluetoothScanning

        visible: root.adapter && root.adapter.discovering
        width: parent.width
        height: 28
        radius: 8
        color: root.ui.surface
        border.width: 1
        border.color: root.ui.borderSoft

        Row {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 10

            Text {
                width: 18
                anchors.verticalCenter: parent.verticalCenter
                text: "󰑓"
                color: root.ui.text
                font.family: "Symbols Nerd Font"
                font.pixelSize: 14
                font.weight: Font.Bold
                horizontalAlignment: Text.AlignHCenter
            }

            Text {
                width: parent.width - 28
                anchors.verticalCenter: parent.verticalCenter
                text: "Scanning for devices"
                color: root.ui.textMuted
                elide: Text.ElideRight
                font.family: "Cantarell"
                font.pixelSize: 12
                font.weight: Font.Bold
            }
        }
    }

    Flickable {
        id: bluetoothScroller

        width: parent.width
        height: Math.max(102, parent.height - bluetoothHeader.height - (bluetoothScanning.visible ? bluetoothScanning.height + 8 : 0) - bluetoothFallback.height - 24)
        clip: true
        contentWidth: width
        contentHeight: bluetoothList.implicitHeight
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: bluetoothList

            width: bluetoothScroller.width
            spacing: 8

            Repeater {
                model: root.devices

                PanelAction {
                    required property var modelData

                    width: parent.width
                    ui: root.ui
                    icon: modelData.connected ? "󰂱" : "󰂯"
                    text: modelData.name || modelData.deviceName || modelData.address
                    subtext: modelData.connected ? root.batteryLabel(modelData) : BluetoothDeviceState.toString(modelData.state)
                    trailingIcon: modelData.connected && root.batteryAvailable(modelData) ? root.batteryIcon(modelData) : ""
                    trailingText: modelData.connected && root.batteryAvailable(modelData) ? root.batteryPercentLabel(modelData) : ""
                    trailingWarning: modelData.connected && root.batteryAvailable(modelData) && root.batteryPercent(modelData) < 30
                    trailingCritical: modelData.connected && root.batteryAvailable(modelData) && root.batteryPercent(modelData) < 15
                    active: modelData.connected
                    onClicked: modelData.connected ? modelData.disconnect() : modelData.connect()
                }
            }
        }
    }

    PanelAction {
        id: bluetoothFallback

        width: parent.width
        ui: root.ui
        icon: "󰂯"
        text: "Open Bluetooth manager"
        subtext: "Native BlueZ fallback"
        onClicked: root.openFallback()
    }
}
