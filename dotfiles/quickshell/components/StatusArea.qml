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
            command: ["loginctl", "lock-session"]
        },
        {
            icon: "󰍃",
            text: "Logout",
            command: ["hyprctl", "dispatch", "exit"]
        },
        {
            icon: "󰤄",
            text: "Suspend",
            command: ["systemctl", "suspend"]
        },
        {
            icon: "󰜉",
            text: "Reboot",
            command: ["systemctl", "reboot"]
        },
        {
            icon: "",
            text: "Shutdown",
            command: ["systemctl", "poweroff"],
            danger: true
        },
    ]
    readonly property string configHome: Quickshell.env("XDG_CONFIG_HOME") || `${Quickshell.env("HOME")}/.config`
    readonly property string powerProfileDisplayPath: Quickshell.env("HYPR_SET_POWER_PROFILE_DISPLAY") || `${configHome}/hypr/scripts/set-power-profile-display`

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
                        id: trayButton
                        required property var modelData

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
                            source: root.trayIconSource(trayButton.modelData)
                            asynchronous: true
                            mipmap: true
                            opacity: trayButton.modelData && trayButton.modelData.status === Status.Passive ? 0.55 : 1
                        }

                        Text {
                            anchors.centerIn: parent
                            visible: !trayButton.modelData || trayIcon.source.toString().length === 0 || trayIcon.status === Image.Error
                            text: root.trayFallbackIcon(trayButton.modelData)
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
                                if (trayButton.modelData.hasMenu)
                                    trayButton.openMenu();
                            } else if (mouse.button === Qt.LeftButton && trayButton.modelData.hasMenu) {
                                trayButton.openMenu();
                            } else if (mouse.button === Qt.MiddleButton) {
                                trayButton.modelData.secondaryActivate();
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

                            const localPoint = trayButton.mapToItem(root, 0, 0);
                            if (root.openTrayMenu(trayButton.modelData, localPoint.x, localPoint.y, trayButton.width, trayButton.height))
                                return;

                            const nativePoint = trayButton.mapToItem(null, trayButton.width / 2, trayButton.height);
                            trayButton.modelData.display(root.parentWindow, nativePoint.x, nativePoint.y);
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
        expanded: root.activePanel.length > 0
        closeKey: root.activePanel
        onVisibleChanged: {
            root.panelVisible = visible;
        }
        onCloseRequested: {
            root.activePanel = "";
        }
        onSurfaceOpened: root.expandedSurfaceReady = true
        onSurfaceClosed: {
            root.activePanel = "";
            root.visiblePanel = "";
            root.expandedSurfaceReady = false;
        }

        Item {
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
                    sourceComponent: root.visiblePanel === "power" ? powerPanel : root.visiblePanel === "network" ? networkPanel : root.visiblePanel === "bluetooth" ? bluetoothPanel : root.visiblePanel === "audio" ? audioPanel : root.visiblePanel === "battery" ? batteryPanel : null
                }
            }
        }
    }

    Components.PopoverSurface {
        id: trayMenuPanel

        ui: root.ui
        anchor.window: root.parentWindow
        anchor.rect.x: root.trayPanelAnchorX()
        anchor.rect.y: root.y
        implicitWidth: 286
        implicitHeight: root.trayPanelHeight()
        originX: root.trayPanelOriginX(implicitWidth)
        originY: root.trayMenuOriginY
        originWidth: root.trayMenuOriginWidth
        originHeight: root.trayMenuOriginHeight
        expanded: root.activeTrayItem !== null
        closeKey: root.activeTrayItem ? "tray" : ""

        onCloseRequested: root.closeTrayMenu()
        onSurfaceClosed: {
            if (root.activeTrayItem) {
                const menu = root.activeTrayRootMenu();
                if (menu)
                    menu.sendClosed();
                root.activeTrayItem = null;
            }
        }

        Column {
            width: parent.width
            height: parent.height
            spacing: 10

            Row {
                width: parent.width
                height: 28
                spacing: 10

                IconImage {
                    visible: root.activeTrayItem && root.trayIconSource(root.activeTrayItem).length > 0
                    anchors.verticalCenter: parent.verticalCenter
                    width: 16
                    height: 16
                    source: root.trayIconSource(root.activeTrayItem)
                    asynchronous: true
                    mipmap: true
                }

                Text {
                    width: parent.width - (root.activeTrayItem && root.trayIconSource(root.activeTrayItem).length > 0 ? 26 : 0)
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.trayPanelTitle()
                    color: root.ui.text
                    elide: Text.ElideRight
                    font.family: "Cantarell"
                    font.pixelSize: 13
                    font.weight: Font.Bold
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: root.ui.borderSoft
            }

            Flickable {
                width: parent.width
                height: Math.max(0, parent.height - 49)
                clip: true
                contentWidth: width
                contentHeight: trayMenuList.implicitHeight
                boundsBehavior: Flickable.StopAtBounds

                Column {
                    id: trayMenuList

                    width: parent.width
                    spacing: 4

                    Repeater {
                        model: root.modelValues(trayMenuOpener.children)

                        Loader {
                            required property var modelData
                            property var entry: modelData

                            width: parent.width
                            sourceComponent: modelData && modelData.isSeparator ? trayMenuSeparator : trayMenuAction
                        }
                    }
                }
            }
        }
    }

    QsMenuOpener {
        id: trayMenuOpener

        menu: root.activeTrayRootMenu()
    }

    Component {
        id: trayMenuSeparator

        Rectangle {
            width: parent.width
            height: 9
            color: "transparent"

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                height: 1
                color: root.ui.borderSoft
            }
        }
    }

    Component {
        id: trayMenuAction

        MouseArea {
            id: trayMenuButton

            property var modelData: parent ? parent.entry : null
            readonly property bool checked: modelData && modelData.checkState === Qt.Checked

            width: parent.width
            height: 32
            hoverEnabled: true
            enabled: modelData && modelData.enabled
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor

            Rectangle {
                anchors.fill: parent
                radius: 8
                color: trayMenuButton.containsMouse && trayMenuButton.enabled ? root.ui.surfaceHover : "transparent"
            }

            Row {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 10

                Item {
                    width: 18
                    height: parent.height

                    Text {
                        visible: trayMenuButton.modelData && trayMenuButton.modelData.buttonType !== QsMenuButtonType.None
                        anchors.centerIn: parent
                        text: trayMenuButton.modelData && trayMenuButton.modelData.buttonType === QsMenuButtonType.RadioButton ? (trayMenuButton.checked ? "●" : "") : (trayMenuButton.checked ? "✓" : "")
                        color: root.ui.text
                        font.family: "Cantarell"
                        font.pixelSize: 12
                        font.weight: Font.Bold
                    }
                }

                Text {
                    width: parent.width - 46 - submenuArrow.width
                    anchors.verticalCenter: parent.verticalCenter
                    text: trayMenuButton.modelData ? trayMenuButton.modelData.text : ""
                    color: trayMenuButton.enabled ? root.ui.text : root.ui.textMuted
                    elide: Text.ElideRight
                    font.family: "Cantarell"
                    font.pixelSize: 12
                    font.weight: Font.Bold
                    opacity: trayMenuButton.enabled ? 1 : 0.55
                }

                Text {
                    id: submenuArrow

                    width: 10
                    anchors.verticalCenter: parent.verticalCenter
                    visible: trayMenuButton.modelData && trayMenuButton.modelData.hasChildren
                    text: "›"
                    color: root.ui.textMuted
                    font.family: "Cantarell"
                    font.pixelSize: 16
                    font.weight: Font.Bold
                }
            }

            onClicked: {
                if (!trayMenuButton.modelData || !trayMenuButton.modelData.enabled)
                    return;

                if (trayMenuButton.modelData.hasChildren) {
                    const point = trayMenuButton.mapToItem(null, trayMenuButton.width, 0);
                    trayMenuButton.modelData.display(trayMenuPanel, point.x, point.y);
                    return;
                }

                trayMenuButton.modelData.sendTriggered();
                root.closeTrayMenu();
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

        if (key === Qt.Key_Up || key === Qt.Key_K) {
            movePowerSelection(-1);
            return true;
        }
        if (key === Qt.Key_Down || key === Qt.Key_J) {
            movePowerSelection(1);
            return true;
        }
        if (key === Qt.Key_Return || key === Qt.Key_Enter) {
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
            return 282;
        if (panelName === "audio")
            return Math.max(456, 304 + ((audioOutputDevices().length + audioInputDevices().length) * 44));
        if (panelName === "battery")
            return root.brightnessAvailable ? 323 : 265;
        if (panelName === "bluetooth")
            return 381;
        return 501;
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

    function activeTrayRootMenu() {
        return trayRootMenuFor(activeTrayItem);
    }

    function openTrayMenu(item, x, y, width, height) {
        const menu = trayRootMenuFor(item);
        if (!menu)
            return false;

        if (activeTrayItem === item) {
            closeTrayMenu();
            return true;
        }

        const previousMenu = activeTrayRootMenu();
        if (previousMenu)
            previousMenu.sendClosed();

        trayMenuOriginX = x;
        trayMenuOriginY = y;
        trayMenuOriginWidth = width;
        trayMenuOriginHeight = height;
        activePanel = "";
        expandedSurfaceReady = false;
        activeTrayItem = item;

        menu.updateLayout();
        menu.sendOpened();
        return true;
    }

    function closeTrayMenu() {
        const menu = activeTrayRootMenu();
        if (menu)
            menu.sendClosed();

        activeTrayItem = null;
    }

    function trayPanelHeight() {
        const entries = root.modelValues(trayMenuOpener.children).length;
        return Math.min(432, Math.max(108, 63 + (entries * 36)));
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
        const target = root.x + trayMenuOriginX + trayMenuOriginWidth - trayMenuPanel.implicitWidth;
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

        Quickshell.execDetached([powerProfileDisplayPath, profile]);
    }
}
