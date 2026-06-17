pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io
import Quickshell.Networking
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray
import Quickshell.Services.UPower
import Quickshell.Widgets
import Quickshell.Wayland
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
    property var trayItems: SystemTray.items.values
    property real brightnessPercent: 0
    property bool brightnessAvailable: false
    property bool idleInhibited: false
    property bool expandedSurfaceReady: false
    readonly property string osdctlPath: "/etc/nixos/dotfiles/hypr/scripts/osdctl"
    readonly property string powerProfileDisplayPath: "/etc/nixos/dotfiles/hypr/scripts/set-power-profile-display"

    implicitWidth: capsuleRow.implicitWidth
    implicitHeight: 28
    width: implicitWidth
    height: implicitHeight

    PwObjectTracker {
        objects: [root.sink, root.source]
    }

    IdleInhibitor {
        window: root.parentWindow
        enabled: root.idleInhibited
    }

    Process {
        id: brightnessReader

        stdout: StdioCollector {
            onStreamFinished: root.loadBrightness(this.text)
        }

        onExited: (exitCode) => {
            if (exitCode !== 0)
                root.brightnessAvailable = false;
        }
    }

    Component.onCompleted: root.refreshBrightness()

    Row {
        id: capsuleRow

        height: 28
        spacing: 6

        Rectangle {
            id: trayContainer
            width: trayRow.implicitWidth + 12
            height: 28
            radius: 999
            visible: root.trayItems.length > 0 && (root.activePanel.length === 0 || !root.expandedSurfaceReady)
            enabled: root.activePanel.length === 0
            color: trayMouse.containsMouse ? root.ui.panelSurfaceHover : root.ui.panelSurface
            border.width: 1
            border.color: root.ui.border

            MouseArea {
                id: trayMouse
                anchors.fill: parent
                hoverEnabled: true
                enabled: root.activePanel.length === 0
                acceptedButtons: Qt.NoButton
            }

            Row {
                id: trayRow
                anchors.centerIn: parent
                spacing: 2

                Repeater {
                    model: root.trayItems

                    MouseArea {
                        required property var modelData

                        id: trayButton

                        implicitWidth: 26
                        implicitHeight: 24
                        width: implicitWidth
                        height: implicitHeight
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton

                        Rectangle {
                            anchors.fill: parent
                            radius: 8
                            color: trayButton.containsMouse ? root.ui.surfaceHover : "transparent"
                        }

                        IconImage {
                            id: trayIcon

                            anchors.centerIn: parent
                            width: 16
                            height: 16
                            source: trayButton.modelData ? trayButton.modelData.icon : ""
                            asynchronous: true
                            mipmap: true
                            opacity: trayButton.modelData && trayButton.modelData.status === Status.Passive ? 0.55 : 1
                        }

                        Text {
                            anchors.centerIn: parent
                            visible: !trayButton.modelData || trayButton.modelData.icon.length === 0 || trayIcon.status === Image.Error
                            text: "•"
                            color: root.ui.textMuted
                            font.family: "Cantarell"
                            font.pixelSize: 16
                            font.weight: Font.Bold
                            verticalAlignment: Text.AlignVCenter
                        }

                        onClicked: mouse => {
                            if (!trayButton.modelData)
                                return;

                            if (mouse.button === Qt.RightButton) {
                                trayButton.openMenu();
                            } else if (mouse.button === Qt.MiddleButton) {
                                trayButton.modelData.secondaryActivate();
                            } else if (trayButton.modelData.onlyMenu && trayButton.modelData.hasMenu) {
                                trayButton.openMenu();
                            } else {
                                trayButton.modelData.activate();
                            }
                        }

                        onWheel: wheel => {
                            if (!trayButton.modelData)
                                return;

                            if (Math.abs(wheel.angleDelta.x) > Math.abs(wheel.angleDelta.y))
                                trayButton.modelData.scroll(wheel.angleDelta.x, true);
                            else
                                trayButton.modelData.scroll(wheel.angleDelta.y, false);
                        }

                        function openMenu() {
                            if (!trayButton.modelData || !trayButton.modelData.hasMenu)
                                return;

                            const point = trayButton.mapToItem(null, trayButton.width / 2, trayButton.height);
                            trayButton.modelData.display(root.parentWindow, point.x, point.y);
                        }
                    }
                }
            }
        }

        Rectangle {
            id: container
            width: systemRow.implicitWidth + 24
            height: 28
            radius: 999
            visible: root.activePanel.length === 0 || !root.expandedSurfaceReady
            enabled: root.activePanel.length === 0
            color: containerMouse.containsMouse ? root.ui.panelSurfaceHover : root.ui.panelSurface
            border.width: 1
            border.color: root.ui.border

            MouseArea {
                id: containerMouse
                anchors.fill: parent
                hoverEnabled: true
                enabled: root.activePanel.length === 0
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
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: mouse => {
                        if (mouse.button === Qt.RightButton)
                            root.runNativeTool(["blueman-manager"]);
                        else
                            root.togglePanel("bluetooth");
                    }
                }

                IconButton {
                    ui: root.ui
                    icon: root.networkIcon()
                    active: root.networkConnected()
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: mouse => {
                        if (mouse.button === Qt.RightButton)
                            root.runNativeTool(["kitty", "--class", "nmtui", "nmtui"]);
                        else
                            root.togglePanel("network");
                    }
                }

                IconButton {
                    ui: root.ui
                    icon: root.volumeIcon()
                    active: root.sink && root.sink.audio && !root.sink.audio.muted
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: mouse => {
                        if (mouse.button === Qt.RightButton)
                            root.runNativeTool(["pavucontrol"]);
                        else
                            root.togglePanel("audio");
                    }
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
                    visible: root.idleInhibited
                    ui: root.ui
                    icon: "󰅶"
                    active: root.idleInhibited
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
    }

    Components.PopoverSurface {
        id: panel
        ui: root.ui
        anchor.window: root.parentWindow
        anchor.rect.x: Math.max(12, root.x + root.width - implicitWidth)
        anchor.rect.y: root.y
        implicitWidth: 360
        implicitHeight: root.panelHeight()
        originX: Math.max(0, implicitWidth - root.width)
        originY: 0
        originWidth: root.width
        originHeight: root.height
        visible: root.activePanel.length > 0
        onVisibleChanged: {
            if (!visible) {
                root.activePanel = "";
                root.expandedSurfaceReady = false;
            }
        }
        onSurfaceOpened: root.expandedSurfaceReady = true
        onSurfaceClosed: root.expandedSurfaceReady = false

        Column {
            anchors.fill: parent
            spacing: 10

            Row {
                width: parent.width
                height: 28

                Text {
                    width: parent.width - statusHeaderRow.implicitWidth
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.panelTitle()
                    color: root.ui.text
                    elide: Text.ElideRight
                    font.family: "Cantarell"
                    font.pixelSize: 13
                    font.weight: Font.Bold
                }

                Row {
                    id: statusHeaderRow
                    anchors.verticalCenter: parent.verticalCenter
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
                        visible: root.idleInhibited
                        ui: root.ui
                        icon: "󰅶"
                        active: root.idleInhibited
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

            Rectangle {
                width: parent.width
                height: 1
                color: root.ui.borderSoft
            }

            Loader {
                width: parent.width
                height: parent.height - 51
                clip: true
                sourceComponent: root.activePanel === "power" ? powerPanel
                    : root.activePanel === "network" ? networkPanel
                    : root.activePanel === "bluetooth" ? bluetoothPanel
                    : root.activePanel === "audio" ? audioPanel
                    : batteryPanel
            }
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
            width: parent.width
            height: parent.height
            spacing: 8

            Row {
                id: networkHeader
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

            Flickable {
                id: wifiScroller

                width: parent.width
                height: Math.max(102, parent.height
                    - networkHeader.height
                    - (passwordPrompt.visible ? passwordPrompt.height + 8 : 0)
                    - networkFallback.height
                    - networkDisconnect.height
                    - 32)
                clip: true
                contentWidth: width
                contentHeight: wifiList.implicitHeight
                boundsBehavior: Flickable.StopAtBounds

                Column {
                    id: wifiList

                    width: wifiScroller.width
                    spacing: 8

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
                }
            }

            Rectangle {
                id: passwordPrompt
                visible: root.passwordTarget !== null
                width: parent.width
                height: root.passwordError.length > 0 ? 104 : 86
                radius: 8
                color: root.ui.surface
                border.width: 1
                border.color: root.ui.borderSoft
                onVisibleChanged: {
                    if (visible) {
                        passwordInput.text = "";
                        passwordInput.forceActiveFocus();
                    }
                }

                Column {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 6

                    Text {
                        width: parent.width
                        text: root.passwordTarget ? `Password for ${root.passwordTarget.name || "hidden network"}` : "Wi-Fi password"
                        color: root.ui.textMuted
                        elide: Text.ElideRight
                        font.family: "Cantarell"
                        font.pixelSize: 11
                        font.weight: Font.Bold
                    }

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
                        Keys.onReturnPressed: root.submitPassword(passwordInput.text)
                        Keys.onEnterPressed: root.submitPassword(passwordInput.text)
                        Keys.onEscapePressed: root.cancelPasswordPrompt(passwordInput)
                    }

                    Row {
                        spacing: 8

                        PanelAction {
                            width: 92
                            ui: root.ui
                            icon: "󰌑"
                            text: "Connect"
                            onClicked: root.submitPassword(passwordInput.text)
                        }

                        PanelAction {
                            width: 82
                            ui: root.ui
                            icon: "󰅖"
                            text: "Cancel"
                            onClicked: root.cancelPasswordPrompt(passwordInput)
                        }
                    }

                    Text {
                        visible: root.passwordError.length > 0
                        width: parent.width
                        text: root.passwordError
                        color: root.ui.warning
                        elide: Text.ElideRight
                        font.family: "Cantarell"
                        font.pixelSize: 11
                        font.weight: Font.Bold
                    }
                }
            }

            PanelAction {
                id: networkFallback
                width: parent.width
                ui: root.ui
                icon: ""
                text: "Open nmtui"
                subtext: "Native NetworkManager fallback"
                onClicked: root.runNativeTool(["kitty", "--class", "nmtui", "nmtui"])
            }

            PanelAction {
                id: networkDisconnect
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

            Rectangle {
                id: bluetoothScanning
                visible: root.bluetoothAdapter && root.bluetoothAdapter.discovering
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
                height: Math.max(102, parent.height
                    - bluetoothHeader.height
                    - (bluetoothScanning.visible ? bluetoothScanning.height + 8 : 0)
                    - bluetoothFallback.height
                    - 24)
                clip: true
                contentWidth: width
                contentHeight: bluetoothList.implicitHeight
                boundsBehavior: Flickable.StopAtBounds

                Column {
                    id: bluetoothList

                    width: bluetoothScroller.width
                    spacing: 8

                    Repeater {
                        model: ScriptModel {
                            values: root.sortedBluetoothDevices()
                        }

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

            PanelAction {
                id: bluetoothFallback
                width: parent.width
                ui: root.ui
                icon: "󰂯"
                text: "Open Bluetooth manager"
                subtext: "Native BlueZ fallback"
                onClicked: root.runNativeTool(["blueman-manager"])
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

            Rectangle {
                width: parent.width
                height: 1
                color: root.ui.borderSoft
            }

            Text {
                width: parent.width
                text: "Output"
                color: root.ui.textMuted
                elide: Text.ElideRight
                font.family: "Cantarell"
                font.pixelSize: 11
                font.weight: Font.Bold
            }

            Repeater {
                model: ScriptModel {
                    values: root.audioOutputDevices()
                }

                PanelAction {
                    required property var modelData

                    width: parent.width
                    ui: root.ui
                    icon: root.audioNodeIcon(modelData)
                    text: root.audioNodeLabel(modelData)
                    subtext: modelData === root.sink ? "Default output" : "Set as default output"
                    active: modelData === root.sink
                    onClicked: Pipewire.preferredDefaultAudioSink = modelData
                }
            }

            Text {
                visible: root.audioInputDevices().length > 0
                width: parent.width
                text: "Input"
                color: root.ui.textMuted
                elide: Text.ElideRight
                font.family: "Cantarell"
                font.pixelSize: 11
                font.weight: Font.Bold
            }

            Repeater {
                model: ScriptModel {
                    values: root.audioInputDevices()
                }

                PanelAction {
                    required property var modelData

                    width: parent.width
                    ui: root.ui
                    icon: "󰍬"
                    text: root.audioNodeLabel(modelData)
                    subtext: modelData === root.source ? "Default input" : "Set as default input"
                    active: modelData === root.source
                    onClicked: Pipewire.preferredDefaultAudioSource = modelData
                }
            }

            PanelAction {
                width: parent.width
                ui: root.ui
                icon: "󰓃"
                text: "Open pavucontrol"
                subtext: "Native PipeWire/Pulse fallback"
                onClicked: root.runNativeTool(["pavucontrol"])
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

            Column {
                visible: root.brightnessAvailable
                width: parent.width
                spacing: 2

                Row {
                    width: parent.width
                    height: 18

                    Text {
                        width: parent.width - 48
                        text: "Brightness"
                        color: root.ui.text
                        elide: Text.ElideRight
                        font.family: "Cantarell"
                        font.pixelSize: 12
                        font.weight: Font.Bold
                    }

                    Text {
                        width: 48
                        text: `${Math.round(root.brightnessPercent)}%`
                        color: root.ui.textMuted
                        horizontalAlignment: Text.AlignRight
                        font.family: "Cantarell"
                        font.pixelSize: 11
                    }
                }

                SliderRow {
                    width: parent.width
                    ui: root.ui
                    icon: "󰃠"
                    value: root.brightnessPercent
                    maximum: 100
                    onMoved: value => root.setBrightness(value)
                }
            }

            PanelAction {
                width: parent.width
                ui: root.ui
                icon: root.idleInhibited ? "󰅶" : "󰾪"
                text: root.idleInhibited ? "Idle inhibited" : "Idle allowed"
                subtext: root.idleInhibited ? "Lock and sleep timers are paused" : "Hypridle timers are active"
                active: root.idleInhibited
                onClicked: root.idleInhibited = !root.idleInhibited
            }

            PanelAction {
                width: parent.width
                ui: root.ui
                icon: "󰌪"
                text: "Power saver"
                active: PowerProfiles.profile === PowerProfile.PowerSaver
                onClicked: root.setPowerProfile("power-saver")
            }

            PanelAction {
                width: parent.width
                ui: root.ui
                icon: ""
                text: "Balanced"
                active: PowerProfiles.profile === PowerProfile.Balanced
                onClicked: root.setPowerProfile("balanced")
            }

            PanelAction {
                visible: PowerProfiles.hasPerformanceProfile
                width: parent.width
                ui: root.ui
                icon: ""
                text: "Performance"
                active: PowerProfiles.profile === PowerProfile.Performance
                onClicked: root.setPowerProfile("performance")
            }
        }
    }

    property var passwordTarget: null
    property string passwordError: ""

    function togglePanel(name) {
        if (activePanel === name) {
            activePanel = "";
            expandedSurfaceReady = false;
        } else {
            expandedSurfaceReady = activePanel.length > 0;
            activePanel = name;
        }

        if (activePanel === "battery")
            refreshBrightness();
    }

    function runAndClose(command) {
        activePanel = "";
        Quickshell.execDetached(command);
    }

    function runNativeTool(command) {
        activePanel = "";
        Quickshell.execDetached(command);
    }

    function panelHeight() {
        if (activePanel === "power")
            return 282;
        if (activePanel === "audio")
            return Math.max(456, 304 + ((audioOutputDevices().length + audioInputDevices().length) * 44));
        if (activePanel === "battery")
            return root.brightnessAvailable ? 323 : 265;
        if (activePanel === "bluetooth")
            return 381;
        return 501;
    }

    function panelTitle() {
        if (activePanel === "power")
            return "Power";
        if (activePanel === "network")
            return "Wi-Fi";
        if (activePanel === "bluetooth")
            return "Bluetooth";
        if (activePanel === "audio")
            return "Audio";
        if (activePanel === "battery")
            return "Power";
        return "";
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
        root.passwordError = "";
    }

    function submitPassword(password) {
        const value = String(password || "");
        if (!passwordTarget)
            return;

        if (value.length < 8) {
            passwordError = "Password must be at least 8 characters";
            return;
        }

        passwordTarget.connectWithPsk(value);
        passwordTarget = null;
        passwordError = "";
    }

    function cancelPasswordPrompt(input) {
        passwordTarget = null;
        passwordError = "";
        if (input)
            input.text = "";
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

    function sortedBluetoothDevices() {
        if (!bluetoothAdapter)
            return [];

        return [...bluetoothAdapter.devices.values].sort((left, right) => {
            if (left.connected !== right.connected)
                return left.connected ? -1 : 1;
            if (left.paired !== right.paired)
                return left.paired ? -1 : 1;

            const leftName = (left.name || left.deviceName || left.address || "").toLowerCase();
            const rightName = (right.name || right.deviceName || right.address || "").toLowerCase();
            return leftName.localeCompare(rightName);
        });
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

    function audioOutputDevices() {
        return Pipewire.nodes.values.filter(node => node.audio && node.isSink && !node.isStream).sort(audioNodeCompare);
    }

    function audioInputDevices() {
        return Pipewire.nodes.values.filter(node => node.audio && !node.isSink && !node.isStream).sort(audioNodeCompare);
    }

    function audioNodeCompare(left, right) {
        if (left === sink || left === source)
            return -1;
        if (right === sink || right === source)
            return 1;
        return audioNodeLabel(left).toLowerCase().localeCompare(audioNodeLabel(right).toLowerCase());
    }

    function audioNodeLabel(node) {
        if (!node)
            return "Audio device";
        return node.description || node.nickname || node.name || "Audio device";
    }

    function audioNodeIcon(node) {
        const label = audioNodeLabel(node).toLowerCase();
        if (label.includes("hdmi") || label.includes("displayport"))
            return "󰍹";
        if (label.includes("headphone") || label.includes("headset"))
            return "󰋋";
        return "󰓃";
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

    function refreshBrightness() {
        brightnessReader.exec(["brightnessctl", "-m"]);
    }

    function loadBrightness(output) {
        const line = String(output || "").trim().split("\n")[0] || "";
        const parts = line.split(",");
        if (parts.length < 4) {
            brightnessAvailable = false;
            return;
        }

        const value = Number(parts[3].replace("%", ""));
        if (Number.isNaN(value)) {
            brightnessAvailable = false;
            return;
        }

        brightnessPercent = Math.max(0, Math.min(100, value));
        brightnessAvailable = true;
    }

    function setBrightness(value) {
        const percentage = Math.round(Math.max(0, Math.min(100, value)));
        brightnessPercent = percentage;
        Quickshell.execDetached(["brightnessctl", "-n2", "set", `${percentage}%`]);
    }

    function setPowerProfile(profile) {
        Quickshell.execDetached([powerProfileDisplayPath, profile]);
    }
}
