pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io
import Quickshell.Networking
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import "." as Components

Item {
    id: root

    required property var ui
    required property var parentWindow

    property string activePanel: ""
    property var devices: Networking.devices.values
    property var bluetoothAdapter: Bluetooth.defaultAdapter
    property var bluetoothDevices: Bluetooth.devices.values
    property var sink: Pipewire.defaultAudioSink
    property var source: Pipewire.defaultAudioSource
    property var battery: UPower.displayDevice

    implicitWidth: container.width
    implicitHeight: 28
    width: implicitWidth
    height: implicitHeight

    PwObjectTracker {
        objects: [root.sink, root.source]
    }

    Rectangle {
        id: container
        width: systemRow.implicitWidth + 24
        height: 28
        radius: 999
        color: containerMouse.containsMouse ? root.ui.surfaceHover : root.ui.surface
        border.width: 1
        border.color: root.ui.border

        MouseArea {
            id: containerMouse
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
        }

        Row {
            id: systemRow
            anchors.centerIn: parent
            spacing: 2

            IconButton {
                ui: root.ui
                icon: root.bluetoothIcon()
                active: root.bluetoothAdapter && root.bluetoothAdapter.enabled
                onClicked: root.togglePanel("bluetooth")
            }

            IconButton {
                ui: root.ui
                icon: root.networkIcon()
                active: root.networkConnected()
                onClicked: root.togglePanel("network")
            }

            IconButton {
                ui: root.ui
                icon: root.volumeIcon()
                active: root.sink && root.sink.audio && !root.sink.audio.muted
                onClicked: root.togglePanel("audio")
            }

            IconButton {
                visible: root.hasBattery()
                ui: root.ui
                icon: root.batteryIcon()
                label: root.hasBattery() ? `${Math.round(root.batteryPercent())}%` : ""
                active: true
                warning: root.hasBattery() && root.batteryPercent() < 30
                critical: root.hasBattery() && root.batteryPercent() < 15
                compact: false
                onClicked: root.togglePanel("battery")
            }

            IconButton {
                ui: root.ui
                icon: ""
                active: true
                onClicked: root.togglePanel("power")
            }
        }
    }

    Components.PopoverSurface {
        id: panel
        ui: root.ui
        anchor.window: root.parentWindow
        anchor.rect.x: Math.max(12, root.x + root.width - implicitWidth)
        anchor.rect.y: 32
        implicitWidth: root.activePanel === "power" ? 220 : 360
        implicitHeight: root.panelHeight()
        visible: root.activePanel.length > 0
        onVisibleChanged: if (!visible) root.activePanel = ""

        Loader {
            anchors.fill: parent
            sourceComponent: root.activePanel === "power" ? powerPanel
                : root.activePanel === "network" ? networkPanel
                : root.activePanel === "bluetooth" ? bluetoothPanel
                : root.activePanel === "audio" ? audioPanel
                : batteryPanel
        }
    }

    Component {
        id: powerPanel

        Column {
            spacing: 6

            PanelAction {
                width: parent.width
                ui: root.ui
                icon: ""
                text: "Lock"
                onClicked: root.runAndClose(["loginctl", "lock-session"])
            }

            PanelAction {
                width: parent.width
                ui: root.ui
                icon: "󰍃"
                text: "Logout"
                onClicked: root.runAndClose(["hyprctl", "dispatch", "exit"])
            }

            PanelAction {
                width: parent.width
                ui: root.ui
                icon: "󰤄"
                text: "Suspend"
                onClicked: root.runAndClose(["systemctl", "suspend"])
            }

            PanelAction {
                width: parent.width
                ui: root.ui
                icon: "󰜉"
                text: "Reboot"
                onClicked: root.runAndClose(["systemctl", "reboot"])
            }

            PanelAction {
                width: parent.width
                ui: root.ui
                icon: ""
                text: "Shutdown"
                danger: true
                onClicked: root.runAndClose(["systemctl", "poweroff"])
            }
        }
    }

    Component {
        id: networkPanel

        Column {
            spacing: 8

            Row {
                width: parent.width
                height: 30

                Text {
                    width: parent.width - 90
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.networkLabel()
                    color: root.ui.text
                    elide: Text.ElideRight
                    font.family: "Cantarell"
                    font.pixelSize: 13
                    font.weight: Font.Bold
                }

                IconButton {
                    ui: root.ui
                    icon: Networking.wifiEnabled ? "󰖩" : "󰖪"
                    label: Networking.wifiEnabled ? "On" : "Off"
                    active: Networking.wifiEnabled
                    compact: false
                    onClicked: Networking.wifiEnabled = !Networking.wifiEnabled
                }

                IconButton {
                    ui: root.ui
                    icon: "󰑓"
                    onClicked: {
                        const wifi = root.wifiDevice();
                        if (wifi)
                            wifi.scannerEnabled = true;
                    }
                }
            }

            Repeater {
                model: root.wifiDevice() ? root.wifiDevice().networks : null

                PanelAction {
                    required property var modelData

                    width: parent.width
                    ui: root.ui
                    icon: root.wifiNetworkIcon(modelData)
                    text: modelData.name || "Hidden network"
                    subtext: modelData.connected ? "Connected" : modelData.known ? "Known" : root.securityLabel(modelData)
                    active: modelData.connected
                    onClicked: {
                        if (modelData.known || modelData.security === WifiSecurityType.Open)
                            modelData.connect();
                        else
                            root.promptForNetwork(modelData);
                    }
                }
            }

            Rectangle {
                visible: root.passwordTarget !== null
                width: parent.width
                height: 74
                radius: 8
                color: root.ui.surface
                border.width: 1
                border.color: root.ui.borderSoft

                Column {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 8

                    TextInput {
                        id: passwordInput
                        width: parent.width
                        height: 24
                        color: root.ui.text
                        selectionColor: root.ui.surfaceStrong
                        selectedTextColor: root.ui.background
                        echoMode: TextInput.Password
                        font.family: "Cantarell"
                        font.pixelSize: 12
                        font.weight: Font.Bold
                        focus: root.passwordTarget !== null
                        clip: true
                    }

                    Row {
                        spacing: 8

                        PanelAction {
                            width: 92
                            ui: root.ui
                            icon: "󰌑"
                            text: "Connect"
                            onClicked: {
                                if (root.passwordTarget)
                                    root.passwordTarget.connectWithPsk(passwordInput.text);
                                root.passwordTarget = null;
                                passwordInput.text = "";
                            }
                        }

                        PanelAction {
                            width: 82
                            ui: root.ui
                            icon: "󰅖"
                            text: "Cancel"
                            onClicked: {
                                root.passwordTarget = null;
                                passwordInput.text = "";
                            }
                        }
                    }
                }
            }

            PanelAction {
                width: parent.width
                ui: root.ui
                icon: "󰤭"
                text: "Disconnect"
                subtext: root.networkConnected() ? root.networkLabel() : ""
                active: false
                onClicked: {
                    const wifi = root.wifiDevice();
                    if (wifi)
                        wifi.disconnect();
                }
            }
        }
    }

    Component {
        id: bluetoothPanel

        Column {
            spacing: 8

            Row {
                width: parent.width
                height: 30

                Text {
                    width: parent.width - 110
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.bluetoothAdapter ? root.bluetoothAdapter.name : "Bluetooth"
                    color: root.ui.text
                    elide: Text.ElideRight
                    font.family: "Cantarell"
                    font.pixelSize: 13
                    font.weight: Font.Bold
                }

                IconButton {
                    ui: root.ui
                    icon: root.bluetoothAdapter && root.bluetoothAdapter.enabled ? "󰂯" : "󰂲"
                    label: root.bluetoothAdapter && root.bluetoothAdapter.enabled ? "On" : "Off"
                    active: root.bluetoothAdapter && root.bluetoothAdapter.enabled
                    compact: false
                    onClicked: if (root.bluetoothAdapter) root.bluetoothAdapter.enabled = !root.bluetoothAdapter.enabled
                }

                IconButton {
                    ui: root.ui
                    icon: "󰑓"
                    active: root.bluetoothAdapter && root.bluetoothAdapter.discovering
                    onClicked: if (root.bluetoothAdapter) root.bluetoothAdapter.discovering = !root.bluetoothAdapter.discovering
                }
            }

            Repeater {
                model: root.bluetoothAdapter ? root.bluetoothAdapter.devices : null

                PanelAction {
                    required property var modelData

                    width: parent.width
                    ui: root.ui
                    icon: modelData.connected ? "󰂱" : "󰂯"
                    text: modelData.name || modelData.deviceName || modelData.address
                    subtext: modelData.connected ? root.bluetoothBatteryLabel(modelData) : BluetoothDeviceState.toString(modelData.state)
                    active: modelData.connected
                    onClicked: modelData.connected ? modelData.disconnect() : modelData.connect()
                }
            }
        }
    }

    Component {
        id: audioPanel

        Column {
            spacing: 10

            SliderRow {
                width: parent.width
                ui: root.ui
                icon: root.volumeIcon()
                value: root.sink && root.sink.audio ? root.sink.audio.volume : 0
                maximum: 1.2
                onMoved: value => {
                    if (root.sink && root.sink.audio)
                        root.sink.audio.volume = value;
                }
            }

            PanelAction {
                width: parent.width
                ui: root.ui
                icon: root.volumeIcon()
                text: root.sink && root.sink.audio && root.sink.audio.muted ? "Unmute output" : "Mute output"
                onClicked: if (root.sink && root.sink.audio) root.sink.audio.muted = !root.sink.audio.muted
            }

            PanelAction {
                width: parent.width
                ui: root.ui
                icon: root.source && root.source.audio && root.source.audio.muted ? "󰍭" : "󰍬"
                text: root.source && root.source.audio && root.source.audio.muted ? "Unmute microphone" : "Mute microphone"
                onClicked: if (root.source && root.source.audio) root.source.audio.muted = !root.source.audio.muted
            }
        }
    }

    Component {
        id: batteryPanel

        Column {
            spacing: 8

            PanelAction {
                width: parent.width
                ui: root.ui
                icon: root.batteryIcon()
                text: root.hasBattery() ? `${Math.round(root.batteryPercent())}% ${UPowerDeviceState.toString(root.battery.state)}` : "Battery"
                subtext: root.batteryDetail()
                warning: root.hasBattery() && root.batteryPercent() < 30
            }

            PanelAction {
                width: parent.width
                ui: root.ui
                icon: "󰌪"
                text: "Power saver"
                active: PowerProfiles.profile === PowerProfile.PowerSaver
                onClicked: PowerProfiles.profile = PowerProfile.PowerSaver
            }

            PanelAction {
                width: parent.width
                ui: root.ui
                icon: "󰾅"
                text: "Balanced"
                active: PowerProfiles.profile === PowerProfile.Balanced
                onClicked: PowerProfiles.profile = PowerProfile.Balanced
            }

            PanelAction {
                visible: PowerProfiles.hasPerformanceProfile
                width: parent.width
                ui: root.ui
                icon: "󰓅"
                text: "Performance"
                active: PowerProfiles.profile === PowerProfile.Performance
                onClicked: PowerProfiles.profile = PowerProfile.Performance
            }
        }
    }

    property var passwordTarget: null

    function togglePanel(name) {
        activePanel = activePanel === name ? "" : name;
    }

    function runAndClose(command) {
        activePanel = "";
        Quickshell.execDetached(command);
    }

    function panelHeight() {
        if (activePanel === "power")
            return 196;
        if (activePanel === "audio")
            return 130;
        if (activePanel === "battery")
            return 184;
        if (activePanel === "bluetooth")
            return 300;
        return 420;
    }

    function wifiDevice() {
        for (let i = 0; i < devices.length; i++) {
            if (devices[i].type === DeviceType.Wifi)
                return devices[i];
        }
        return null;
    }

    function wiredDevice() {
        for (let i = 0; i < devices.length; i++) {
            if (devices[i].type === DeviceType.Wired)
                return devices[i];
        }
        return null;
    }

    function connectedNetwork(device) {
        if (!device)
            return null;
        for (let i = 0; i < device.networks.values.length; i++) {
            if (device.networks.values[i].connected)
                return device.networks.values[i];
        }
        return null;
    }

    function networkConnected() {
        const wired = wiredDevice();
        if (wired && wired.connected)
            return true;
        const wifi = wifiDevice();
        return wifi && wifi.connected;
    }

    function networkLabel() {
        const wired = wiredDevice();
        if (wired && wired.connected)
            return "Ethernet";
        const wifi = wifiDevice();
        const network = connectedNetwork(wifi);
        if (network)
            return network.name;
        return Networking.wifiEnabled ? "Wi-Fi" : "Network disabled";
    }

    function networkIcon() {
        const wired = wiredDevice();
        if (wired && wired.connected)
            return "󰈀";
        if (!Networking.wifiEnabled)
            return "󰖪";
        const wifi = wifiDevice();
        const network = connectedNetwork(wifi);
        return network ? wifiNetworkIcon(network) : "󰤭";
    }

    function wifiNetworkIcon(network) {
        const strength = network && network.signalStrength ? network.signalStrength : 0;
        if (strength > 0.75)
            return "󰤨";
        if (strength > 0.50)
            return "󰤥";
        if (strength > 0.25)
            return "󰤢";
        return "󰤟";
    }

    function securityLabel(network) {
        if (!network || network.security === WifiSecurityType.Open)
            return "Open";
        return WifiSecurityType.toString(network.security);
    }

    function promptForNetwork(network) {
        root.passwordTarget = network;
    }

    function bluetoothIcon() {
        if (!bluetoothAdapter || !bluetoothAdapter.enabled)
            return "󰂲";
        for (let i = 0; i < bluetoothDevices.length; i++) {
            if (bluetoothDevices[i].connected)
                return "󰂱";
        }
        return "󰂯";
    }

    function bluetoothBatteryLabel(device) {
        if (device.batteryAvailable)
            return `Connected, ${Math.round(device.battery * 100)}%`;
        return "Connected";
    }

    function volumeIcon() {
        if (!sink || !sink.audio)
            return "󰕿";
        if (sink.audio.muted || sink.audio.volume <= 0.01)
            return "󰝟";
        if (sink.audio.volume < 0.34)
            return "󰕿";
        if (sink.audio.volume < 0.67)
            return "󰖀";
        return "󰕾";
    }

    function hasBattery() {
        return battery && battery.ready && battery.isLaptopBattery;
    }

    function batteryPercent() {
        if (!hasBattery())
            return 0;
        const value = Number(battery.percentage || 0);
        return value <= 1 ? value * 100 : value;
    }

    function batteryIcon() {
        if (!hasBattery())
            return "󰂑";
        if (battery.state === UPowerDeviceState.Charging || battery.state === UPowerDeviceState.PendingCharge)
            return "󰂄";
        const percentage = batteryPercent();
        if (percentage >= 90)
            return "󰁹";
        if (percentage >= 60)
            return "󰂀";
        if (percentage >= 30)
            return "󰁾";
        if (percentage >= 15)
            return "󰁻";
        return "󰁺";
    }

    function batteryDetail() {
        if (!hasBattery())
            return "";
        if (battery.timeToEmpty > 0)
            return `${formatDuration(battery.timeToEmpty)} remaining`;
        if (battery.timeToFull > 0)
            return `${formatDuration(battery.timeToFull)} until full`;
        return `${Math.abs(battery.changeRate).toFixed(1)} W`;
    }

    function formatDuration(seconds) {
        const hours = Math.floor(seconds / 3600);
        const minutes = Math.round((seconds % 3600) / 60);
        return `${hours}h ${minutes}m`;
    }
}
