import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell as QS

QS.PanelWindow {
    id: root

    property bool showing: false
    property string icon: ""
    property string label: ""
    property real level: 0
    readonly property string runtimeDir: Quickshell.env("XDG_RUNTIME_DIR") || "/tmp"

    anchors {
        top: true
        left: true
    }

    margins {
        top: Math.round(root.screenHeight() * 0.34)
        left: Math.max(12, Math.round((root.screenWidth() - root.implicitWidth) / 2))
    }

    implicitWidth: 396
    implicitHeight: 100
    visible: showing
    exclusiveZone: 0
    aboveWindows: true
    focusable: false
    color: "transparent"

    ColorScheme {
        id: colorScheme
    }

    FileView {
        id: stateFile

        path: `${root.runtimeDir}/quickshell-osd/state.json`
        blockLoading: true
        watchChanges: true
        printErrors: false

        onLoaded: root.loadState()
        onFileChanged: reload()
    }

    Rectangle {
        anchors.fill: parent
        radius: 16
        color: colorScheme.panelSurface
        border.width: 1
        border.color: colorScheme.border

        Row {
            anchors.fill: parent
            anchors.leftMargin: 20
            anchors.rightMargin: 20
            spacing: 16

            Text {
                width: 42
                anchors.verticalCenter: parent.verticalCenter
                text: root.icon
                color: colorScheme.text
                font.family: "Symbols Nerd Font"
                font.pixelSize: 28
                font.weight: Font.Bold
                horizontalAlignment: Text.AlignHCenter
            }

            Column {
                width: parent.width - 58
                anchors.verticalCenter: parent.verticalCenter
                spacing: 12

                Text {
                    width: parent.width
                    text: root.label
                    color: colorScheme.text
                    elide: Text.ElideRight
                    font.family: "Cantarell"
                    font.pixelSize: 14
                    font.weight: Font.Bold
                }

                Rectangle {
                    width: parent.width
                    height: 8
                    radius: 999
                    color: colorScheme.surface

                    Rectangle {
                        width: Math.max(parent.height, Math.min(parent.width, parent.width * root.normalizedLevel()))
                        height: parent.height
                        radius: parent.radius
                        color: colorScheme.surfaceStrong

                        Behavior on width {
                            NumberAnimation {
                                duration: 90
                                easing.type: Easing.OutCubic
                            }
                        }
                    }
                }
            }
        }
    }

    function loadState() {
        try {
            const state = JSON.parse(stateFile.text());
            root.showing = !!state.visible;
            root.icon = state.icon || "";
            root.label = state.text || "";
            root.level = Number(state.value || 0);
        } catch (error) {
            root.showing = false;
        }
    }

    function normalizedLevel() {
        return Math.max(0, Math.min(1, root.level / 100));
    }

    function screenWidth() {
        return root.screen && root.screen.width ? root.screen.width : 1920;
    }

    function screenHeight() {
        return root.screen && root.screen.height ? root.screen.height : 1080;
    }
}
