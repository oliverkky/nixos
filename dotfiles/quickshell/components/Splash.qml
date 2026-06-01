import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell as QS

QS.PanelWindow {
    id: root

    property string message: "Hello World!"
    readonly property string homeDir: Quickshell.env("HOME") || ""

    anchors {
        bottom: true
        left: true
    }

    margins {
        bottom: 56
        left: Math.max(24, Math.round((root.screenWidth() - root.implicitWidth) / 2))
    }

    implicitWidth: Math.min(900, Math.max(280, root.screenWidth() - 48))
    implicitHeight: 64
    exclusiveZone: 0
    aboveWindows: false
    focusable: false
    color: "transparent"

    ColorScheme {
        id: colorScheme
    }

    FileView {
        id: messageFile

        path: `${root.homeDir}/.config/hypr/splash_messages.conf`
        blockLoading: true
        watchChanges: true
        printErrors: false

        onLoaded: root.pickMessage()
        onFileChanged: reload()
    }

    Text {
        anchors.fill: parent
        text: root.message
        color: colorScheme.text
        opacity: 0.92
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
        font.family: "Cantarell"
        font.pixelSize: 18
        font.weight: Font.Bold
        style: Text.Raised
        styleColor: colorScheme.shadow
    }

    Component.onCompleted: pickMessage()

    function pickMessage() {
        try {
            const lines = messageFile.text()
                .split(/\r?\n/)
                .map(line => line.trim())
                .filter(line => line.length > 0 && !line.startsWith("#"));

            root.message = lines.length > 0
                ? lines[Math.floor(Math.random() * lines.length)]
                : "Hello World!";
        } catch (error) {
            root.message = "Hello World!";
        }
    }

    function screenWidth() {
        return root.screen && root.screen.width ? root.screen.width : 1920;
    }
}
