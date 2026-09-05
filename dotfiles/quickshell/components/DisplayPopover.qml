pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import "." as Components

Item {
    id: root

    required property var ui
    required property var parentWindow

    property string activeMode: ""
    property string visibleMode: ""
    property var monitors: []
    property string focusedMonitor: ""
    property string stateError: ""
    property string stateCommandError: ""
    property int selectedIndex: 0
    readonly property var layoutActions: [
        {
            icon: "󰍹",
            text: "Duplicate",
            subtext: "Mirror this screen to every connected display",
            command: "duplicate"
        },
        {
            icon: "󰍺",
            text: "Extend",
            subtext: "Place connected displays side by side",
            command: "extend"
        },
        {
            icon: "󰹑",
            text: "This screen only",
            subtext: "Disable every other display",
            command: "current-only"
        },
        {
            icon: "󰹐",
            text: "Other screen only",
            subtext: "Use the first other connected display",
            command: "other-only"
        },
    ]
    readonly property var scaleChoices: ["auto", "1", "1.25", "1.5", "1.66", "2"]
    // Resolve through PATH so a shell carrying an old Nix store environment
    // cannot pin the popover to a removed desktopctl generation.
    readonly property var displayCommand: ["desktopctl", "display"]

    width: 1
    height: 1

    Process {
        id: stateReader

        stdout: StdioCollector {
            onStreamFinished: root.loadState(this.text)
        }

        stderr: StdioCollector {
            onStreamFinished: root.stateCommandError = String(this.text || "").trim()
        }

        onExited: exitCode => {
            if (exitCode !== 0) {
                const detail = root.stateCommandError;
                root.stateError = detail.length > 0 ? detail : `displayctl exited with status ${exitCode}`;
            }
        }
    }

    Timer {
        id: refreshAfterAction

        interval: 450
        repeat: false
        onTriggered: root.refreshState()
    }

    onActiveModeChanged: {
        if (activeMode.length > 0) {
            visibleMode = activeMode;
            selectedIndex = 0;
            refreshState();
        }
    }

    Components.PopoverSurface {
        id: panel

        ui: root.ui
        anchor.window: root.parentWindow
        anchor.rect.x: root.parentWindow ? Math.max(12, root.parentWindow.width - implicitWidth - 12) : 12
        anchor.rect.y: root.parentWindow && root.parentWindow.screen
            ? Math.max(12, Math.round((root.parentWindow.screen.height - implicitHeight) / 2))
            : 40
        implicitWidth: 420
        implicitHeight: root.panelHeight() + 12
        originX: implicitWidth + 24
        originY: 0
        originWidth: 1
        originHeight: implicitHeight
        expanded: root.activeMode.length > 0
        closeKey: root.activeMode
        onCloseRequested: root.activeMode = ""
        onSurfaceOpened: keyHandler.forceActiveFocus()
        onSurfaceClosed: {
            root.activeMode = "";
            root.visibleMode = "";
            root.selectedIndex = 0;
        }

        Item {
            id: keyHandler

            anchors.fill: parent
            focus: panel.visible
            Keys.onPressed: event => {
                if (root.handleKey(event.key)) {
                    event.accepted = true;
                }
            }

            Column {
                anchors.fill: parent
                spacing: 10

                Row {
                    width: parent.width
                    height: 30
                    spacing: 8

                    Text {
                        width: parent.width - refreshButton.width - 8
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.panelTitle()
                        color: root.ui.text
                        elide: Text.ElideRight
                        font.family: "Cantarell"
                        font.pixelSize: 13
                        font.weight: Font.Bold
                    }

                    Components.IconButton {
                        id: refreshButton

                        ui: root.ui
                        icon: "󰑓"
                        label: "Refresh"
                        compact: false
                        onClicked: root.refreshState()
                    }
                }

                Text {
                    visible: root.stateError.length > 0
                    width: parent.width
                    text: root.stateError
                    color: root.ui.warning
                    elide: Text.ElideRight
                    font.family: "Cantarell"
                    font.pixelSize: 11
                    font.weight: Font.Bold
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: root.ui.borderSoft
                }

                Loader {
                    width: parent.width
                    height: parent.height - 43 - (root.stateError.length > 0 ? 24 : 0)
                    clip: true
                    sourceComponent: root.visibleMode === "current" ? currentPanel : layoutPanel
                }
            }
        }
    }

    Component {
        id: layoutPanel

        Column {
            width: parent.width
            spacing: 8

            Text {
                width: parent.width
                text: root.monitorSummary()
                color: root.ui.textMuted
                elide: Text.ElideRight
                font.family: "Cantarell"
                font.pixelSize: 11
                font.weight: Font.Bold
            }

            Repeater {
                model: root.layoutActions

                Components.PanelAction {
                    required property int index
                    required property var modelData

                    width: parent.width
                    ui: root.ui
                    icon: modelData.icon
                    text: modelData.text
                    subtext: modelData.subtext
                    warning: modelData.command === "other-only" && root.connectedMonitors().length < 2
                    selected: root.selectedIndex === index
                    onEntered: root.selectedIndex = index
                    onClicked: root.runLayout(modelData.command)
                }
            }
        }
    }

    Component {
        id: currentPanel

        Column {
            width: parent.width
            height: parent.height
            spacing: 10

            Text {
                width: parent.width
                text: root.currentMonitorLabel()
                color: root.ui.textMuted
                elide: Text.ElideRight
                font.family: "Cantarell"
                font.pixelSize: 11
                font.weight: Font.Bold
            }

            Text {
                width: parent.width
                text: "Resolution @ refresh rate"
                color: root.ui.text
                elide: Text.ElideRight
                font.family: "Cantarell"
                font.pixelSize: 12
                font.weight: Font.Bold
            }

            Flickable {
                width: parent.width
                height: Math.max(116, parent.height - 202)
                clip: true
                contentWidth: width
                contentHeight: modeList.implicitHeight
                boundsBehavior: Flickable.StopAtBounds

                Column {
                    id: modeList

                    width: parent.width
                    spacing: 6

                    Repeater {
                        model: root.currentModes()

                        Components.PanelAction {
                            required property int index
                            required property string modelData

                            width: parent.width
                            ui: root.ui
                            icon: "󰍹"
                            text: root.modeLabel(modelData)
                            subtext: root.currentModeActive(modelData) ? "Current" : ""
                            active: root.currentModeActive(modelData)
                            selected: root.selectedIndex === index
                            onEntered: root.selectedIndex = index
                            onClicked: root.setMode(modelData)
                        }
                    }
                }
            }

            Text {
                width: parent.width
                text: "Scale"
                color: root.ui.text
                elide: Text.ElideRight
                font.family: "Cantarell"
                font.pixelSize: 12
                font.weight: Font.Bold
            }

            Row {
                width: parent.width
                spacing: 6

                Repeater {
                    model: root.scaleChoices

                    Components.PanelAction {
                        required property int index
                        required property string modelData

                        width: Math.floor((parent.width - 30) / 6)
                        ui: root.ui
                        text: modelData
                        subtext: ""
                        active: root.currentScaleActive(modelData)
                        selected: root.selectedIndex === root.currentModes().length + index
                        onEntered: root.selectedIndex = root.currentModes().length + index
                        onClicked: root.setScale(modelData)
                    }
                }
            }
        }
    }

    function openLayout() {
        activeMode = activeMode === "layout" ? "" : "layout";
    }

    function openCurrent() {
        activeMode = activeMode === "current" ? "" : "current";
    }

    function refreshState() {
        stateError = "";
        stateCommandError = "";
        stateReader.exec(displayCommand.concat(["state"]));
    }

    function loadState(output) {
        try {
            const parsed = JSON.parse(String(output || "{}"));
            monitors = parsed.monitors || [];
            focusedMonitor = parsed.focused || "";
            stateError = "";
        } catch (error) {
            stateError = "Invalid display state";
            monitors = [];
            focusedMonitor = "";
        }
    }

    function panelTitle() {
        return visibleMode === "current" ? "Current screen" : "Project";
    }

    function panelHeight() {
        return visibleMode === "current" ? 560 : 260;
    }

    function enabledMonitors() {
        return monitors.filter(monitor => monitor.enabled);
    }

    function connectedMonitors() {
        // `hyprctl monitors all` already limits this list to connected outputs.
        // Mirrored outputs may temporarily have no availableModes entry.
        return monitors;
    }

    function currentMonitor() {
        for (let i = 0; i < monitors.length; i++) {
            if (monitors[i].name === focusedMonitor)
                return monitors[i];
        }

        const enabled = enabledMonitors();
        return enabled.length > 0 ? enabled[0] : (monitors.length > 0 ? monitors[0] : null);
    }

    function currentMonitorName() {
        const monitor = currentMonitor();
        return monitor ? monitor.name : "";
    }

    function currentMonitorLabel() {
        const monitor = currentMonitor();
        if (!monitor)
            return "No monitor detected";

        const description = monitor.description && monitor.description !== monitor.name ? ` · ${monitor.description}` : "";
        return `${monitor.name}${description}`;
    }

    function monitorSummary() {
        const enabled = enabledMonitors();
        if (enabled.length === 0)
            return "No active displays";

        return enabled.map(monitor => monitor.name).join(" + ");
    }

    function currentModes() {
        const monitor = currentMonitor();
        if (!monitor)
            return [];

        if (monitor.modes && monitor.modes.length > 0)
            return monitor.modes;

        return monitor.currentMode ? [monitor.currentMode] : [];
    }

    function currentScale() {
        const monitor = currentMonitor();
        return monitor ? String(monitor.scale || "1") : "1";
    }

    function currentMode() {
        const monitor = currentMonitor();
        return monitor ? String(monitor.currentMode || "") : "";
    }

    function normalizeMode(mode) {
        return String(mode || "").replace(/Hz$/, "");
    }

    function modeLabel(mode) {
        return normalizeMode(mode);
    }

    function currentModeActive(mode) {
        return normalizeMode(mode) === normalizeMode(currentMode());
    }

    function currentScaleActive(scale) {
        if (scale === "auto")
            return false;

        return Math.abs(Number(scale) - Number(currentScale())) < 0.001;
    }

    function selectableCount() {
        if (visibleMode === "current")
            return currentModes().length + scaleChoices.length;

        return layoutActions.length;
    }

    function moveSelection(delta) {
        const count = selectableCount();
        if (count <= 0)
            return;

        selectedIndex = (selectedIndex + delta + count) % count;
    }

    function handleKey(key) {
        if (key === Qt.Key_Escape) {
            activeMode = "";
            return true;
        }

        if (key === Qt.Key_Up || key === Qt.Key_Left || key === Qt.Key_K || key === Qt.Key_H) {
            moveSelection(-1);
            return true;
        }

        if (key === Qt.Key_Down || key === Qt.Key_Right || key === Qt.Key_J || key === Qt.Key_L) {
            moveSelection(1);
            return true;
        }

        if (key === Qt.Key_Return || key === Qt.Key_Enter) {
            activateSelected();
            return true;
        }

        if (key === Qt.Key_R) {
            refreshState();
            return true;
        }

        return false;
    }

    function activateSelected() {
        if (visibleMode !== "current") {
            if (selectedIndex >= 0 && selectedIndex < layoutActions.length)
                runLayout(layoutActions[selectedIndex].command);
            return;
        }

        const modes = currentModes();
        if (selectedIndex < modes.length) {
            setMode(modes[selectedIndex]);
            return;
        }

        const scaleIndex = selectedIndex - modes.length;
        if (scaleIndex >= 0 && scaleIndex < scaleChoices.length)
            setScale(scaleChoices[scaleIndex]);
    }

    function runLayout(command) {
        const monitor = currentMonitorName();
        if (monitor.length === 0)
            return;

        Quickshell.execDetached(displayCommand.concat(["layout", command, monitor]));
        activeMode = "";
    }

    function setMode(mode) {
        const monitor = currentMonitorName();
        if (monitor.length === 0)
            return;

        Quickshell.execDetached(displayCommand.concat(["set-mode", monitor, mode, currentScale()]));
        refreshAfterAction.restart();
    }

    function setScale(scale) {
        const monitor = currentMonitorName();
        const mode = currentMode() || (currentModes().length > 0 ? currentModes()[0] : "preferred");
        if (monitor.length === 0)
            return;

        Quickshell.execDetached(displayCommand.concat(["set-mode", monitor, mode, scale]));
        refreshAfterAction.restart();
    }
}
