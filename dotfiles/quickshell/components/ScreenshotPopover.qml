import QtQuick
import Quickshell
import Quickshell as QS
import Quickshell.Hyprland
import Quickshell.Wayland

QS.PanelWindow {
    id: root

    required property var shellRoot
    property string captureMode: "area"
    property bool includePointer: true
    property bool delayed: false
    property bool open: false
    property int focusedControl: 0
    readonly property string iconFont: "JetBrainsMonoNL Nerd Font"
    readonly property bool isActiveScreen: {
        if (Hyprland.focusedMonitor)
            return root.screen && root.screen.name === Hyprland.focusedMonitor.name;

        return Quickshell.screens.length > 0 && root.screen === Quickshell.screens[0];
    }

    anchors {
        bottom: true
        left: true
        right: true
    }

    margins.bottom: 28
    implicitHeight: open ? 202 : 1
    exclusiveZone: 0
    aboveWindows: true
    focusable: open
    color: "transparent"
    mask: Region {
        item: surface
    }

    WlrLayershell.namespace: "oliver.quickshell.screenshot"

    ColorScheme {
        id: colorScheme
    }

    function modeForControl(control) {
        return ["area", "screen", "window"][control];
    }

    function setFocusedControl(control) {
        focusedControl = Math.max(0, Math.min(5, control));

        if (focusedControl < 3)
            captureMode = modeForControl(focusedControl);
    }

    function capture() {
        if (focusedControl < 3)
            captureMode = modeForControl(focusedControl);

        root.open = false;
        Quickshell.execDetached([
            "desktopctl", "screenshot", root.captureMode,
            root.delayed ? "3" : "0",
            root.includePointer ? "pointer" : "no-pointer"
        ]);
    }

    function selectFocusedControl() {
        if (focusedControl < 3)
            captureMode = modeForControl(focusedControl);
        else if (focusedControl === 3)
            includePointer = !includePointer;
        else if (focusedControl === 4)
            delayed = !delayed;
        else
            capture();
    }

    function moveLeft() {
        if (focusedControl > 0 && focusedControl < 3) {
            setFocusedControl(focusedControl - 1);
            return;
        }

        if (focusedControl >= 3)
            setFocusedControl(2);
    }

    function moveRight() {
        if (focusedControl < 2) {
            setFocusedControl(focusedControl + 1);
            return;
        }

        if (focusedControl === 2)
            setFocusedControl(3);
    }

    function moveUp() {
        if (focusedControl > 3)
            setFocusedControl(focusedControl - 1);
    }

    function moveDown() {
        if (focusedControl < 3)
            setFocusedControl(3);
        else if (focusedControl < 5)
            setFocusedControl(focusedControl + 1);
    }

    Connections {
        target: root.shellRoot

        function onOpenScreenshotMenu() {
            if (!root.isActiveScreen)
                return;

            if (root.open)
                root.capture();
            else
                root.open = true;
        }
    }

    HyprlandFocusGrab {
        windows: [root]
        active: root.open
        onCleared: root.open = false
    }

    BackgroundEffect.blurRegion: Region {
        item: surface
        radius: surface.radius
    }

    Rectangle {
        id: surface

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        width: 530
        height: 174
        visible: root.open
        radius: 18
        color: colorScheme.popoverSurface
        border.width: 1
        border.color: colorScheme.border
        focus: root.open
        onVisibleChanged: {
            if (visible) {
                root.setFocusedControl(Math.max(0, ["area", "screen", "window"].indexOf(root.captureMode)));
                forceActiveFocus();
            }
        }

        Keys.onEscapePressed: root.open = false
        Keys.onReturnPressed: root.capture()
        Keys.onEnterPressed: root.capture()
        Keys.onSpacePressed: root.selectFocusedControl()
        Keys.onPressed: event => {
            if (event.key === Qt.Key_Left || event.key === Qt.Key_H) {
                root.moveLeft();
                event.accepted = true;
            } else if (event.key === Qt.Key_Right || event.key === Qt.Key_L) {
                root.moveRight();
                event.accepted = true;
            } else if (event.key === Qt.Key_Up || event.key === Qt.Key_K) {
                root.moveUp();
                event.accepted = true;
            } else if (event.key === Qt.Key_Down || event.key === Qt.Key_J) {
                root.moveDown();
                event.accepted = true;
            }
        }

        Row {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10

            Repeater {
                model: [
                    { mode: "area", icon: "󰹑", label: "Selection" },
                    { mode: "screen", icon: "󰍹", label: "Screen" },
                    { mode: "window", icon: "󰖲", label: "Window" }
                ]

                delegate: Rectangle {
                    required property var modelData
                    required property int index
                    width: 104
                    height: parent.height
                    radius: 12
                    color: root.captureMode === modelData.mode || root.focusedControl === index ? colorScheme.surfaceHover : "transparent"
                    border.width: root.captureMode === modelData.mode || root.focusedControl === index ? 1 : 0
                    border.color: root.focusedControl === index ? colorScheme.accent : colorScheme.border

                    Column {
                        anchors.centerIn: parent
                        width: parent.width
                        spacing: 8

                        Text {
                            width: parent.width
                            text: modelData.icon
                            color: colorScheme.text
                            horizontalAlignment: Text.AlignHCenter
                            font.family: root.iconFont
                            font.pixelSize: 28
                        }

                        Text {
                            width: parent.width
                            text: modelData.label
                            color: colorScheme.text
                            horizontalAlignment: Text.AlignHCenter
                            font.family: "Cantarell"
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.setFocusedControl(parent.index)
                    }
                }
            }

            Rectangle {
                width: 1
                height: parent.height - 20
                anchors.verticalCenter: parent.verticalCenter
                color: colorScheme.borderSoft
            }

            Column {
                width: 122
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                ToggleRow {
                    ui: colorScheme
                    icon: "󰗊"
                    label: "Pointer"
                    checked: root.includePointer
                    highlighted: root.focusedControl === 3
                    onToggled: {
                        root.setFocusedControl(3);
                        root.includePointer = checked;
                    }
                }

                ToggleRow {
                    ui: colorScheme
                    icon: "󰔛"
                    label: "Delay 3s"
                    checked: root.delayed
                    highlighted: root.focusedControl === 4
                    onToggled: {
                        root.setFocusedControl(4);
                        root.delayed = checked;
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 38
                    radius: 10
                    color: colorScheme.accent
                    border.width: root.focusedControl === 5 ? 1 : 0
                    border.color: colorScheme.text

                    Text {
                        anchors.centerIn: parent
                        text: "Capture"
                        color: colorScheme.background
                        font.family: "Cantarell"
                        font.pixelSize: 13
                        font.weight: Font.Bold
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.setFocusedControl(5);
                            root.capture();
                        }
                    }
                }
            }
        }
    }
}
