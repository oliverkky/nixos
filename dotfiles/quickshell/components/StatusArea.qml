pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io
import Quickshell.Networking
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray
import Quickshell.Services.UPower
import Quickshell.Wayland
import "." as Components

Item {
    id: root

    required property var ui
    required property var parentWindow

    property string activePanel: ""
    property string visiblePanel: ""
    property bool panelVisible: false
    property var devices: root.modelValues(Networking.devices)
    property var bluetoothAdapter: Bluetooth.defaultAdapter
    property var bluetoothDevices: root.modelValues(Bluetooth.devices)
    property var powerDevices: root.modelValues(UPower.devices)
    property var sink: Pipewire.defaultAudioSink
    property var source: Pipewire.defaultAudioSource
    property var battery: UPower.displayDevice
    property var trayItems: root.modelValues(SystemTray.items)
    property var activeTrayItem: null
    property real trayMenuOriginX: 0
    property real trayMenuOriginY: 0
    property real trayMenuOriginWidth: 26
    property real trayMenuOriginHeight: 24
    property real brightnessPercent: 0
    property bool brightnessAvailable: false
    property bool idleInhibited: false
    property bool expandedSurfaceReady: false
    property int powerSelectedIndex: 0
    readonly property bool powerProfilesAvailable: root.hasBattery()
    readonly property var powerActions: [
        {
            icon: "",
            text: "Lock",
            key: Qt.Key_L,
            command: ["loginctl", "lock-session"]
        },
        {
            icon: "󰍃",
            text: "Sign off",
            key: Qt.Key_S,
            command: ["hyprctl", "dispatch", "exit"]
        },
        {
            icon: "󰤄",
            text: "Hibernate",
            key: Qt.Key_H,
            command: ["systemctl", "hibernate"]
        },
        {
            icon: "󰜉",
            text: "Reboot",
            key: Qt.Key_R,
            command: ["systemctl", "reboot"]
        },
        {
            icon: "",
            text: "Power off",
            key: Qt.Key_P,
            command: ["systemctl", "poweroff"],
            danger: true
        },
    ]

    implicitWidth: capsuleRow.implicitWidth
    implicitHeight: 30
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

        onExited: exitCode => {
            if (exitCode !== 0)
                root.brightnessAvailable = false;
        }
    }

    Component.onCompleted: root.refreshBrightness()

    onActivePanelChanged: {
        if (activePanel.length > 0)
            visiblePanel = activePanel;
    }

    Row {
        id: capsuleRow

        height: 30
        spacing: 0

        Components.StatusTrayRow {
            id: trayButtons

            ui: root.ui
            trayItems: root.trayItems
            parentWindow: root.parentWindow
            iconSource: root.trayIconSource
            fallbackIcon: root.trayFallbackIcon
            openMenu: (item, x, y, width, height) => root.openTrayMenu(item, trayButtons.x + x, trayButtons.y + y, width, height)
            visible: root.trayItems.length > 0
            enabled: root.activePanel.length === 0 && !panel.visible
        }

        Item {
            // Keep the tray beside the expanded status surface instead of
            // letting that surface grow over it. Since StatusArea is anchored
            // to the right edge, widening this gap moves only the tray left.
            visible: trayButtons.visible
            width: 7 + panel.progress * Math.max(0, panel.implicitWidth - container.width)
            height: 1
        }

        Rectangle {
            id: container
            width: systemButtons.implicitWidth + 26
            height: 30
            radius: 999
            enabled: root.activePanel.length === 0 && !panel.visible
            opacity: panel.visible ? Math.max(0, 1 - panel.progress * 1.4) : 1
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

            Components.StatusButtonRow {
                id: systemButtons

                anchors.centerIn: parent
                ui: root.ui
                bluetoothIcon: root.bluetoothIcon()
                bluetoothActive: root.bluetoothAdapter && root.bluetoothAdapter.enabled
                networkIcon: root.networkIcon()
                networkActive: root.networkConnected()
                volumeIcon: root.volumeIcon()
                volumeActive: root.sink && root.sink.audio && !root.sink.audio.muted
                hasBattery: root.hasBattery()
                batteryIcon: root.batteryIcon()
                batteryPercent: root.batteryPercent()
                batteryWarning: root.hasBattery() && root.batteryPercent() < 30
                batteryCritical: root.hasBattery() && root.batteryPercent() < 15
                idleInhibited: root.idleInhibited
                contextActionsEnabled: true
                onBluetoothClicked: mouse => {
                    if (mouse.button === Qt.RightButton)
                        root.runNativeTool(["blueman-manager"]);
                    else
                        root.togglePanel("bluetooth");
                }
                onNetworkClicked: mouse => {
                    if (mouse.button === Qt.RightButton)
                        root.runNativeTool(["kitty", "--class", "nmtui", "nmtui"]);
                    else
                        root.togglePanel("network");
                }
                onVolumeClicked: mouse => {
                    if (mouse.button === Qt.RightButton)
                        root.runNativeTool(["pavucontrol"]);
                    else
                        root.togglePanel("audio");
                }
                onBatteryClicked: root.togglePanel("battery")
                onIdleClicked: root.togglePanel("battery")
                onPowerClicked: root.togglePanel("power")
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
        originX: Math.max(0, implicitWidth - container.width)
        originY: 0
        originWidth: container.width
        originHeight: root.height
        expanded: root.activePanel.length > 0
        closeKey: root.activePanel
        onVisibleChanged: {
            root.panelVisible = visible;
        }
        onCloseRequested: {
            root.activePanel = "";
        }
        onSurfaceOpened: {
            root.expandedSurfaceReady = true;
            if (root.activePanel === "power")
                panelKeyboardHandler.forceActiveFocus();
        }
        onSurfaceClosed: {
            root.activePanel = "";
            root.visiblePanel = "";
            root.expandedSurfaceReady = false;
        }

        Item {
            id: panelKeyboardHandler

            anchors.fill: parent
            focus: root.visiblePanel === "power"
            Keys.onPressed: event => {
                if (root.handlePowerKey(event.key))
                    event.accepted = true;
            }

            Column {
                width: parent.width
                height: parent.height
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
                        transform: Translate {
                            x: (1 - panel.contentProgress) * -8
                        }
                    }

                    Components.StatusButtonRow {
                        id: statusHeaderRow

                        anchors.verticalCenter: parent.verticalCenter
                        ui: root.ui
                        bluetoothIcon: root.bluetoothIcon()
                        bluetoothActive: root.bluetoothAdapter && root.bluetoothAdapter.enabled
                        networkIcon: root.networkIcon()
                        networkActive: root.networkConnected()
                        volumeIcon: root.volumeIcon()
                        volumeActive: root.sink && root.sink.audio && !root.sink.audio.muted
                        hasBattery: root.hasBattery()
                        batteryIcon: root.batteryIcon()
                        batteryPercent: root.batteryPercent()
                        batteryWarning: root.hasBattery() && root.batteryPercent() < 30
                        batteryCritical: root.hasBattery() && root.batteryPercent() < 15
                        idleInhibited: root.idleInhibited
                        onBluetoothClicked: root.togglePanel("bluetooth")
                        onNetworkClicked: root.togglePanel("network")
                        onVolumeClicked: root.togglePanel("audio")
                        onBatteryClicked: root.togglePanel("battery")
                        onIdleClicked: root.togglePanel("battery")
                        onPowerClicked: root.togglePanel("power")
                        transform: Translate {
                            x: (1 - panel.contentProgress) * 12
                            y: (1 - panel.contentProgress) * -2
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
                    sourceComponent: root.visiblePanel === "power" ? powerPanel : root.visiblePanel === "network" ? networkPanel : root.visiblePanel === "bluetooth" ? bluetoothPanel : root.visiblePanel === "audio" ? audioPanel : root.visiblePanel === "battery" ? batteryPanel : null
                }
            }
        }
    }

    Components.StatusTrayMenu {
        id: trayMenuPanel

        ui: root.ui
        parentWindow: root.parentWindow
        activeTrayItem: root.activeTrayItem
        // QsMenuOpener must receive the persistent QsMenuHandle. Some
        // applications (notably Steam) populate handle.menu asynchronously,
        // so passing that transient root entry leaves the opener empty.
        rootMenu: root.activeTrayMenuHandle()
        iconSource: root.trayIconSource
        titleProvider: root.trayPanelTitle
        anchorX: root.trayPanelAnchorX()
        anchorY: root.y
        originX: root.trayPanelOriginX(implicitWidth)
        originY: root.trayMenuOriginY
        originWidth: root.trayMenuOriginWidth
        originHeight: root.trayMenuOriginHeight

        onCloseMenuRequested: root.closeTrayMenu()
        onSurfaceClosed: {
            if (root.activeTrayItem) {
                const menu = root.activeTrayRootMenu();
                if (menu)
                    menu.closed();
                root.activeTrayItem = null;
            }
        }
    }

    Component {
        id: powerPanel

        PowerPanel {
            ui: root.ui
            actions: root.powerActions
            selectedIndex: root.powerSelectedIndex
            onEntered: index => root.powerSelectedIndex = index
            onRunAction: index => root.runPowerAction(index)
        }
    }

    Component {
        id: networkPanel

        NetworkPanel {
            ui: root.ui
            networks: root.wifiDevice() ? root.modelValues(root.wifiDevice().networks) : []
            iconForNetwork: root.wifiNetworkIcon
            securityLabel: root.securityLabel
            wifiEnabled: Networking.wifiEnabled
            label: root.networkLabel()
            connected: root.networkConnected()
            passwordTarget: root.passwordTarget
            passwordError: root.passwordError
            onToggleWifi: Networking.wifiEnabled = !Networking.wifiEnabled
            onRescan: {
                const wifi = root.wifiDevice();
                if (wifi)
                    wifi.scannerEnabled = true;
            }
            onConnectNetwork: network => root.promptForNetwork(network)
            onSubmitPassword: password => root.submitPassword(password)
            onCancelPassword: input => root.cancelPasswordPrompt(input)
            onOpenFallback: root.runNativeTool(["kitty", "--class", "nmtui", "nmtui"])
            onDisconnectWifi: {
                const wifi = root.wifiDevice();
                if (wifi)
                    wifi.disconnect();
            }
        }
    }

    Component {
        id: bluetoothPanel

        BluetoothPanel {
            ui: root.ui
            adapter: root.bluetoothAdapter
            devices: root.sortedBluetoothDevices()
            batteryLabel: root.bluetoothBatteryLabel
            batteryAvailable: root.bluetoothBatteryAvailable
            batteryIcon: root.bluetoothBatteryIcon
            batteryPercent: root.bluetoothBatteryPercent
            batteryPercentLabel: root.bluetoothBatteryPercentLabel
            onOpenFallback: root.runNativeTool(["blueman-manager"])
            onConnectA2dp: device => root.connectBluetoothA2dp(device)
            onSetBluetoothEnabled: enabled => root.setBluetoothEnabled(enabled)
        }
    }

    Component {
        id: audioPanel

        AudioPanel {
            ui: root.ui
            sink: root.sink
            source: root.source
            outputDevices: root.audioOutputDevices()
            inputDevices: root.audioInputDevices()
            volumeIcon: root.volumeIcon
            audioNodeIcon: root.audioNodeIcon
            audioNodeLabel: root.audioNodeLabel
            onOpenFallback: root.runNativeTool(["pavucontrol"])
        }
    }

    Component {
        id: batteryPanel

        BatteryPanel {
            ui: root.ui
            battery: root.battery
            hasBattery: root.hasBattery()
            batteryPercent: root.batteryPercent()
            batteryDetail: root.batteryDetail()
            batteryIcon: root.batteryIcon()
            brightnessAvailable: root.brightnessAvailable
            brightnessPercent: root.brightnessPercent
            idleInhibited: root.idleInhibited
            powerProfilesAvailable: root.powerProfilesAvailable
            powerSaverActive: root.powerProfileActive(PowerProfile.PowerSaver)
            balancedActive: root.powerProfileActive(PowerProfile.Balanced)
            performanceActive: root.powerProfileActive(PowerProfile.Performance)
            hasPerformanceProfile: PowerProfiles.hasPerformanceProfile
            onSetBrightness: value => root.setBrightness(value)
            onToggleIdleInhibited: root.idleInhibited = !root.idleInhibited
            onSetPowerProfile: profile => root.setPowerProfile(profile)
        }
    }

    property var passwordTarget: null
    property string passwordError: ""

    function togglePanel(name) {
        closeTrayMenu();

        if (activePanel === name) {
            activePanel = "";
        } else {
            expandedSurfaceReady = activePanel.length > 0;
            activePanel = name;
        }

        if (activePanel === "power")
            powerSelectedIndex = 0;
        if (activePanel === "battery")
            refreshBrightness();
    }

    function openPowerMenu() {
        closeTrayMenu();
        expandedSurfaceReady = activePanel.length > 0;
        activePanel = "power";
        powerSelectedIndex = 0;
    }

    function runAndClose(command) {
        closeTrayMenu();
        activePanel = "";
        Quickshell.execDetached(command);
    }

    function runPowerAction(index) {
        if (index < 0 || index >= powerActions.length)
            return;

        runAndClose(powerActions[index].command);
    }

    function movePowerSelection(delta) {
        if (powerActions.length === 0)
            return;

        powerSelectedIndex = (powerSelectedIndex + delta + powerActions.length) % powerActions.length;
    }

    function handlePowerKey(key) {
        if (activePanel !== "power")
            return false;

        for (let i = 0; i < powerActions.length; i++) {
            if (powerActions[i].key === key) {
                runPowerAction(i);
                return true;
            }
        }

        if (key === Qt.Key_Up || key === Qt.Key_Left || key === Qt.Key_K) {
            movePowerSelection(-1);
            return true;
        }
        if (key === Qt.Key_Down || key === Qt.Key_Right || key === Qt.Key_J) {
            movePowerSelection(1);
            return true;
        }
        if (key === Qt.Key_Return || key === Qt.Key_Enter || key === Qt.Key_Space) {
            runPowerAction(powerSelectedIndex);
            return true;
        }

        return false;
    }

    function runNativeTool(command) {
        closeTrayMenu();
        activePanel = "";
        Quickshell.execDetached(command);
    }

    function panelHeight() {
        const panelName = visiblePanel.length > 0 ? visiblePanel : activePanel;
        if (panelName === "power")
            return 272;
        if (panelName === "audio")
            return Math.max(468, 316 + ((audioOutputDevices().length + audioInputDevices().length) * 44));
        if (panelName === "battery")
            return root.brightnessAvailable ? 356 : 296;
        if (panelName === "bluetooth")
            return 393;
        return 513;
    }

    function panelTitle() {
        const panelName = visiblePanel.length > 0 ? visiblePanel : activePanel;
        if (panelName === "power")
            return "Power";
        if (panelName === "network")
            return "Wi-Fi";
        if (panelName === "bluetooth")
            return "Bluetooth";
        if (panelName === "audio")
            return "Audio";
        if (panelName === "battery")
            return "Power";
        return "";
    }

    function modelValues(model) {
        if (!model)
            return [];
        if (model.values)
            return model.values;
        return [];
    }

    function trayRootMenuFor(item) {
        if (!item || !item.menu)
            return null;

        return item.menu.menu || null;
    }

    function trayMenuHandleFor(item) {
        return item && item.menu ? item.menu : null;
    }

    function activeTrayMenuHandle() {
        return trayMenuHandleFor(activeTrayItem);
    }

    function activeTrayRootMenu() {
        return trayRootMenuFor(activeTrayItem);
    }

    function openTrayMenu(item, x, y, width, height) {
        if (!item || !item.hasMenu)
            return false;

        if (activeTrayItem === item) {
            closeTrayMenu();
            return true;
        }

        const previousMenu = activeTrayRootMenu();
        if (previousMenu)
            previousMenu.closed();

        trayMenuOriginX = x;
        trayMenuOriginY = y;
        trayMenuOriginWidth = width;
        trayMenuOriginHeight = height;
        activePanel = "";
        expandedSurfaceReady = false;
        activeTrayItem = item;

        // The DBusMenu handle, rather than its transient root entry, is the
        // QsMenuOpener input. It owns loading and updating the item model.
        const handle = activeTrayMenuHandle();
        if (!handle)
            return true;

        const menu = activeTrayRootMenu();
        if (!menu)
            return true;

        menu.opened();
        return true;
    }

    function closeTrayMenu() {
        const menu = activeTrayRootMenu();
        if (menu)
            menu.closed();

        activeTrayItem = null;
    }

    function trayPanelTitle() {
        if (!activeTrayItem)
            return "Menu";

        return activeTrayItem.tooltipTitle || activeTrayItem.title || activeTrayItem.id || "Menu";
    }

    function trayIconSource(item) {
        if (!item || !item.icon)
            return "";

        const icon = String(item.icon);
        if (icon.startsWith("/"))
            return `file://${icon}`;
        if (icon.includes(":"))
            return icon;

        return "";
    }

    function trayFallbackIcon(item) {
        const label = String(item ? item.icon || item.title || item.id || item.tooltipTitle || "" : "").toLowerCase();
        if (label.includes("audio") || label.includes("volume") || label.includes("headset"))
            return "󰕾";
        if (label.includes("battery") || label.includes("power"))
            return "󰁹";
        if (label.includes("bluetooth"))
            return "󰂯";
        if (label.includes("network") || label.includes("wifi") || label.includes("wireless"))
            return "󰤨";
        return "•";
    }

    function trayPanelAnchorX() {
        // Keep the active 16px tray icon in the same horizontal position in
        // both states. The clicked 28px tray button contains the icon with 6px
        // side insets, and the expanded header keeps the icon 12px from the
        // panel edge, so the panel edge sits 6px past the original button.
        const target = root.x + trayMenuOriginX + trayMenuOriginWidth + 6 - trayMenuPanel.implicitWidth;
        const maxX = root.parentWindow && root.parentWindow.width ? root.parentWindow.width - trayMenuPanel.implicitWidth - 12 : target;

        return Math.max(12, Math.min(Math.max(12, maxX), target));
    }

    function trayPanelOriginX(panelWidth) {
        const anchorX = trayPanelAnchorX() - root.x;
        return Math.max(0, Math.min(panelWidth - trayMenuOriginWidth, trayMenuOriginX - anchorX));
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
        const networks = root.modelValues(device.networks);
        for (let i = 0; i < networks.length; i++) {
            if (networks[i].connected)
                return networks[i];
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
        return "Connected";
    }

    function bluetoothBatteryAvailable(device) {
        return (device && device.batteryAvailable) || root.bluetoothUPowerDevice(device) !== null;
    }

    function bluetoothBatteryPercent(device) {
        if (!device)
            return 0;

        const source = device.batteryAvailable ? device : root.bluetoothUPowerDevice(device);
        if (!source)
            return 0;

        const value = Number(source.percentage !== undefined ? source.percentage : source.battery || 0);
        return value <= 1 ? value * 100 : value;
    }

    function bluetoothBatteryPercentLabel(device) {
        return `${Math.round(bluetoothBatteryPercent(device))}%`;
    }

    function bluetoothBatteryIcon(device) {
        const percentage = bluetoothBatteryPercent(device);
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

    function bluetoothUPowerDevice(device) {
        if (!device)
            return null;

        const address = root.normalizedDeviceKey(device.address || "");
        const deviceName = root.normalizedDeviceKey(device.name || device.deviceName || "");

        for (let i = 0; i < powerDevices.length; i++) {
            const powerDevice = powerDevices[i];
            if (!powerDevice || !powerDevice.ready || powerDevice.isLaptopBattery || powerDevice.percentage <= 0)
                continue;

            const nativePath = root.normalizedDeviceKey(powerDevice.nativePath || "");
            const model = root.normalizedDeviceKey(powerDevice.model || "");
            if (address.length > 0 && nativePath.includes(address))
                return powerDevice;
            if (deviceName.length > 0 && model.length > 0 && (model.includes(deviceName) || deviceName.includes(model)))
                return powerDevice;
        }

        return null;
    }

    function normalizedDeviceKey(value) {
        return String(value).toLowerCase().replace(/[^a-z0-9]/g, "");
    }

    function sortedBluetoothDevices() {
        if (!bluetoothAdapter)
            return [];

        return [...root.modelValues(bluetoothAdapter.devices)].sort((left, right) => {
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
        return root.modelValues(Pipewire.nodes).filter(node => node.audio && node.isSink && !node.isStream).sort(audioNodeCompare);
    }

    function audioInputDevices() {
        return root.modelValues(Pipewire.nodes).filter(node => node.audio && !node.isSink && !node.isStream).sort(audioNodeCompare);
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

    function powerProfileActive(profile) {
        return powerProfilesAvailable && PowerProfiles.profile === profile;
    }

    function setPowerProfile(profile) {
        if (!powerProfilesAvailable)
            return;

        Quickshell.execDetached(["desktopctl", "power", "profile", "set", profile]);
    }

    function setBluetoothEnabled(enabled) {
        if (bluetoothAdapter)
            bluetoothAdapter.enabled = enabled;

        Quickshell.execDetached(["bluetoothctl", "power", enabled ? "on" : "off"]);
    }

    function connectBluetoothA2dp(device) {
        if (!device)
            return;

        // Start the connection through Quickshell so a missing or stale helper
        // can never turn the device row into a no-op. The helper then selects
        // A2DP once BlueZ has exposed the device to PipeWire.
        device.connect();

        const address = device.address || "";
        if (!address)
            return;

        Quickshell.execDetached(["desktopctl", "bluetooth", "connect-a2dp", address]);
    }
}
