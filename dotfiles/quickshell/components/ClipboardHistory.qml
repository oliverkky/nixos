pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell as QS
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland

QS.PanelWindow {
    id: root

    required property var shellRoot
    property bool open: false
    property int selectedIndex: 0
    property var revealedItems: ({})
    property string loadError: ""
    readonly property string iconFont: "Symbols Nerd Font"
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
    implicitHeight: open ? Math.min(590, Math.max(320, screen ? screen.height - 92 : 590)) : 1
    exclusiveZone: 0
    aboveWindows: true
    focusable: open
    color: "transparent"
    mask: Region { item: surface }

    WlrLayershell.namespace: "oliver.quickshell.clipboard"

    ColorScheme {
        id: colorScheme
    }

    ListModel {
        id: allItems
    }

    ListModel {
        id: filteredItems
    }

    Process {
        id: historyReader

        command: ["desktopctl", "clipboard", "list"]
        stdout: StdioCollector {
            onStreamFinished: root.loadHistory(this.text)
        }
        stderr: StdioCollector {
            onStreamFinished: root.loadError = String(this.text || "").trim()
        }
        onExited: exitCode => {
            if (exitCode !== 0 && root.loadError.length === 0)
                root.loadError = `Could not read clipboard history (status ${exitCode})`;
        }
    }

    Connections {
        target: root.shellRoot

        function onOpenClipboardHistory() {
            if (!root.isActiveScreen)
                return;

            if (root.open) {
                root.open = false;
                return;
            }

            root.open = true;
            root.refresh();
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
        width: Math.min(640, Math.max(300, root.width - 24))
        height: root.implicitHeight
        visible: root.open
        radius: 18
        color: colorScheme.popoverSurface
        border.width: 1
        border.color: colorScheme.border
        focus: root.open

        onVisibleChanged: {
            if (visible) {
                searchInput.text = "";
                searchInput.forceActiveFocus();
            }
        }

        Keys.onEscapePressed: root.open = false

        Column {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10

            Row {
                width: parent.width
                height: 30
                spacing: 10

                Text {
                    width: 20
                    anchors.verticalCenter: parent.verticalCenter
                    text: "󰅇"
                    color: colorScheme.text
                    horizontalAlignment: Text.AlignHCenter
                    font.family: root.iconFont
                    font.pixelSize: 16
                    font.weight: Font.Bold
                }

                Text {
                    width: Math.max(0, parent.width - 20 - refreshButton.width - 20)
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Clipboard"
                    color: colorScheme.text
                    font.family: "Cantarell"
                    font.pixelSize: 13
                    font.weight: Font.Bold
                }

                IconButton {
                    ui: colorScheme
                    icon: "󰑓"
                    label: "Refresh"
                    compact: false
                    onClicked: root.refresh()
                }
            }

            Rectangle {
                width: parent.width
                height: 38
                radius: 10
                color: colorScheme.surface
                border.width: searchInput.activeFocus ? 1 : 0
                border.color: colorScheme.accent

                Text {
                    width: 20
                    anchors.left: parent.left
                    anchors.leftMargin: 11
                    anchors.verticalCenter: parent.verticalCenter
                    text: "󰍉"
                    color: colorScheme.textMuted
                    horizontalAlignment: Text.AlignHCenter
                    font.family: root.iconFont
                    font.pixelSize: 14
                }

                TextInput {
                    id: searchInput

                    anchors.left: parent.left
                    anchors.leftMargin: 42
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    color: colorScheme.text
                    selectionColor: colorScheme.surfaceStrong
                    selectedTextColor: colorScheme.background
                    font.family: "Cantarell"
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    clip: true
                    focus: root.open

                    onTextChanged: root.applyFilter(text)
                    Keys.onEscapePressed: root.open = false
                    Keys.onUpPressed: root.moveSelection(-1)
                    Keys.onDownPressed: root.moveSelection(1)
                    Keys.onReturnPressed: root.copySelected()
                    Keys.onEnterPressed: root.copySelected()
                }

                Text {
                    anchors.left: searchInput.left
                    anchors.verticalCenter: parent.verticalCenter
                    visible: searchInput.text.length === 0
                    text: "Search clipboard history"
                    color: colorScheme.textMuted
                    font.family: "Cantarell"
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: colorScheme.borderSoft
            }

            Item {
                width: parent.width
                height: Math.max(0, parent.height - 100)

                Text {
                    anchors.centerIn: parent
                    visible: filteredItems.count === 0
                    text: root.loadError.length > 0
                        ? root.loadError
                        : historyReader.running ? "Loading clipboard history…" : "No matching clipboard items"
                    color: root.loadError.length > 0 ? colorScheme.warning : colorScheme.textMuted
                    font.family: "Cantarell"
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                }

                ListView {
                    id: historyList

                    anchors.fill: parent
                    visible: filteredItems.count > 0
                    clip: true
                    spacing: 7
                    boundsBehavior: Flickable.StopAtBounds
                    model: filteredItems
                    currentIndex: root.selectedIndex

                    delegate: Rectangle {
                        id: clipDelegate

                        required property int index
                        required property string clipId
                        required property string preview
                        required property bool imageItem
                        required property bool sensitive
                        property string imageSource: ""
                        readonly property bool selected: root.selectedIndex === index
                        readonly property bool revealed: !!root.revealedItems[clipId]

                        width: historyList.width
                        height: imageItem ? 154 : 62
                        radius: 12
                        color: mouseArea.containsMouse || selected ? colorScheme.surfaceHover : colorScheme.surface
                        border.width: selected ? 1 : 0
                        border.color: colorScheme.accent

                        Process {
                            id: previewLoader

                            command: ["desktopctl", "clipboard", "preview", clipDelegate.clipId]
                            stdout: StdioCollector {
                                onStreamFinished: {
                                    const path = String(this.text || "").trim();
                                    if (path.length > 0)
                                        clipDelegate.imageSource = `file://${path}`;
                                }
                            }
                        }

                        Component.onCompleted: {
                            if (clipDelegate.imageItem)
                                previewLoader.running = true;
                        }

                        Row {
                            z: 1
                            anchors.fill: parent
                            anchors.margins: 9
                            spacing: 11

                            Rectangle {
                                width: clipDelegate.imageItem ? 178 : 36
                                height: parent.height
                                radius: 8
                                color: colorScheme.panelSurface
                                clip: true

                                Image {
                                    anchors.fill: parent
                                    anchors.margins: 3
                                    visible: clipDelegate.imageItem && clipDelegate.imageSource.length > 0
                                    source: clipDelegate.imageSource
                                    asynchronous: true
                                    cache: true
                                    fillMode: Image.PreserveAspectFit
                                    mipmap: true
                                }

                                Text {
                                    anchors.centerIn: parent
                                    visible: !clipDelegate.imageItem || clipDelegate.imageSource.length === 0
                                    text: clipDelegate.imageItem ? "󰋩" : clipDelegate.sensitive ? "󰌾" : "󰦨"
                                    color: clipDelegate.sensitive ? colorScheme.warning : colorScheme.textMuted
                                    font.family: root.iconFont
                                    font.pixelSize: clipDelegate.imageItem ? 24 : 15
                                    font.weight: Font.Bold
                                }
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                width: Math.max(0, parent.width - parent.spacing - (clipDelegate.imageItem ? 178 : 36))
                                spacing: 4

                                Text {
                                    width: parent.width
                                    text: clipDelegate.imageItem
                                        ? "Image"
                                        : clipDelegate.sensitive && !clipDelegate.revealed
                                            ? "Sensitive text hidden"
                                            : root.displayText(clipDelegate.preview)
                                    color: colorScheme.text
                                    elide: Text.ElideRight
                                    maximumLineCount: clipDelegate.imageItem ? 1 : 2
                                    wrapMode: Text.Wrap
                                    font.family: "Cantarell"
                                    font.pixelSize: 12
                                    font.weight: Font.Bold
                                }

                                Text {
                                    width: parent.width - (revealButton.visible ? 34 : 0)
                                    text: clipDelegate.imageItem
                                        ? root.imageDescription(clipDelegate.preview)
                                        : clipDelegate.sensitive && !clipDelegate.revealed
                                            ? "••••••••••••  ·  Enter copies without revealing"
                                            : `Clipboard item ${clipDelegate.clipId}`
                                    color: clipDelegate.sensitive && !clipDelegate.revealed ? colorScheme.warning : colorScheme.textMuted
                                    elide: Text.ElideRight
                                    font.family: "Cantarell"
                                    font.pixelSize: 11
                                    font.weight: Font.DemiBold
                                }
                            }
                        }

                        Rectangle {
                            id: revealButton

                            z: 2
                            visible: clipDelegate.sensitive && !clipDelegate.imageItem
                            anchors.right: parent.right
                            anchors.rightMargin: 10
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 8
                            width: 27
                            height: 25
                            radius: 7
                            color: revealMouse.containsMouse ? colorScheme.surfaceHover : colorScheme.panelSurface

                            Text {
                                anchors.centerIn: parent
                                text: clipDelegate.revealed ? "󰈈" : "󰈉"
                                color: colorScheme.textMuted
                                font.family: root.iconFont
                                font.pixelSize: 13
                            }

                            MouseArea {
                                id: revealMouse

                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.toggleReveal(clipDelegate.clipId)
                            }
                        }

                        MouseArea {
                            id: mouseArea

                            anchors.fill: parent
                            z: 0
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onContainsMouseChanged: {
                                if (containsMouse)
                                    root.selectedIndex = clipDelegate.index;
                            }
                            onClicked: root.copyItem(clipDelegate.clipId)
                        }
                    }
                }
            }
        }
    }

    function refresh() {
        loadError = "";
        allItems.clear();
        filteredItems.clear();
        selectedIndex = 0;
        historyReader.running = true;
    }

    function loadHistory(raw) {
        let parsed = [];
        try {
            parsed = JSON.parse(String(raw || "[]"));
        } catch (error) {
            loadError = `Invalid clipboard history: ${error}`;
            return;
        }

        allItems.clear();
        for (let i = 0; i < parsed.length; i++) {
            const preview = String(parsed[i].preview || "");
            const imageItem = isImage(preview);
            allItems.append({
                "clipId": String(parsed[i].id || ""),
                "preview": preview,
                "imageItem": imageItem,
                "sensitive": !imageItem && isSensitive(preview)
            });
        }
        applyFilter(searchInput.text);
    }

    function applyFilter(query) {
        const needle = String(query || "").trim().toLowerCase();
        filteredItems.clear();
        for (let i = 0; i < allItems.count; i++) {
            const item = allItems.get(i);
            if (needle.length === 0 || String(item.preview).toLowerCase().indexOf(needle) >= 0) {
                filteredItems.append({
                    "clipId": item.clipId,
                    "preview": item.preview,
                    "imageItem": item.imageItem,
                    "sensitive": item.sensitive
                });
            }
        }
        selectedIndex = filteredItems.count > 0 ? 0 : -1;
        if (selectedIndex >= 0)
            historyList.positionViewAtIndex(selectedIndex, ListView.Contain);
    }

    function moveSelection(delta) {
        if (filteredItems.count === 0)
            return;
        selectedIndex = Math.max(0, Math.min(filteredItems.count - 1, selectedIndex + delta));
        historyList.positionViewAtIndex(selectedIndex, ListView.Contain);
    }

    function copySelected() {
        if (selectedIndex >= 0 && selectedIndex < filteredItems.count)
            copyItem(filteredItems.get(selectedIndex).clipId);
    }

    function copyItem(clipId) {
        Quickshell.execDetached(["desktopctl", "clipboard", "copy", String(clipId)]);
        open = false;
    }

    function toggleReveal(clipId) {
        const next = Object.assign({}, revealedItems);
        next[clipId] = !next[clipId];
        revealedItems = next;
    }

    function displayText(value) {
        return String(value || "").replace(/\u0000/g, " · ").replace(/\s+/g, " ").trim();
    }

    function isImage(value) {
        return /^\[\[ binary data .*\b(?:png|jpe?g|webp|gif|bmp|tiff?)\b.*\]\]$/i.test(String(value || ""));
    }

    function imageDescription(value) {
        const text = String(value || "");
        const dimensions = text.match(/\b(\d+x\d+)\b/);
        const format = text.match(/\b(png|jpe?g|webp|gif|bmp|tiff?)\b/i);
        const size = text.match(/\b(\d+(?:\.\d+)?\s+(?:B|KiB|MiB|GiB))\b/i);
        return [format ? format[1].toUpperCase() : "Image", dimensions ? dimensions[1] : "", size ? size[1] : ""]
            .filter(part => part.length > 0).join("  ·  ");
    }

    function isSensitive(value) {
        const text = displayText(value);
        if (text.length === 0 || text.length > 256)
            return false;

        if (/\b(password|passwd|passphrase|pwd|secret|api[_ -]?key|access[_ -]?token|auth[_ -]?token|private[_ -]?key)\b\s*[:=]/i.test(text))
            return true;

        if (/^(https?:\/\/|file:\/\/|\/|~\/)/i.test(text) || /\s/.test(text))
            return false;

        if (/^\d{6,8}$/.test(text))
            return true;

        if (text.length < 12 || text.length > 128)
            return false;

        let classes = 0;
        if (/[a-z]/.test(text)) classes++;
        if (/[A-Z]/.test(text)) classes++;
        if (/\d/.test(text)) classes++;
        if (/[^A-Za-z0-9]/.test(text)) classes++;
        return classes >= 3;
    }
}
