import QtQuick
import Quickshell.Io

Item {
    id: root

    required property var ui

    property bool microphoneActive: false
    property bool cameraActive: false
    readonly property bool active: root.microphoneActive || root.cameraActive

    implicitWidth: iconRow.implicitWidth + 20
    implicitHeight: 30
    width: root.active ? implicitWidth : 0
    height: implicitHeight
    visible: width > 0
    clip: true

    Behavior on width {
        NumberAnimation {
            duration: 140
            easing.type: Easing.OutCubic
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: 999
        color: root.ui.panelSurface
        border.width: 1
        border.color: root.ui.border
        opacity: root.active ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: 100
                easing.type: Easing.OutCubic
            }
        }
    }

    Row {
        id: iconRow

        anchors.centerIn: parent
        spacing: 6
        opacity: root.active ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: 100
                easing.type: Easing.OutCubic
            }
        }

        Text {
            visible: root.microphoneActive
            text: "󰍬"
            color: root.ui.text
            font.family: "Symbols Nerd Font"
            font.pixelSize: 14
            font.weight: Font.Bold
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        Text {
            visible: root.cameraActive
            text: "󰄀"
            color: root.ui.text
            font.family: "Symbols Nerd Font"
            font.pixelSize: 14
            font.weight: Font.Bold
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }

    Process {
        id: privacyReader

        stdout: StdioCollector {
            onStreamFinished: root.loadPipewireState(this.text)
        }

        onExited: exitCode => {
            if (exitCode !== 0) {
                root.microphoneActive = false;
                root.cameraActive = false;
            }
        }
    }

    Timer {
        interval: 1200
        repeat: true
        running: true
        onTriggered: root.refreshPrivacyState()
    }

    Component.onCompleted: root.refreshPrivacyState()

    function refreshPrivacyState() {
        if (!privacyReader.running)
            privacyReader.exec(["pw-dump"]);
    }

    function loadPipewireState(output) {
        try {
            const objects = JSON.parse(String(output || "[]"));
            const nodeClasses = {};
            const links = [];

            for (let i = 0; i < objects.length; i++) {
                const object = objects[i];
                if (!object || !object.info)
                    continue;

                if (object.type === "PipeWire:Interface:Node") {
                    const props = object.info.props || {};
                    nodeClasses[object.id] = String(props["media.class"] || "");
                } else if (object.type === "PipeWire:Interface:Link") {
                    links.push({
                        output: object.info["output-node-id"],
                        input: object.info["input-node-id"],
                        state: String(object.info.state || "").toLowerCase()
                    });
                }
            }

            let microphone = false;
            let camera = false;

            for (let i = 0; i < links.length; i++) {
                const link = links[i];
                if (link.state !== "active")
                    continue;

                const outputClass = nodeClasses[link.output] || "";
                const inputClass = nodeClasses[link.input] || "";

                microphone = microphone || root.isCaptureLink(outputClass, inputClass, "Audio/Source", "Stream/Input/Audio");
                camera = camera || root.isCaptureLink(outputClass, inputClass, "Video/Source", "Stream/Input/Video") || root.isCaptureLink(outputClass, inputClass, "Video/Source", "Video/Sink");

                if (microphone && camera)
                    break;
            }

            root.microphoneActive = microphone;
            root.cameraActive = camera;
        } catch (error) {
            root.microphoneActive = false;
            root.cameraActive = false;
        }
    }

    function isCaptureLink(outputClass, inputClass, deviceClass, peerClass) {
        return (outputClass === deviceClass && inputClass === peerClass) || (outputClass === peerClass && inputClass === deviceClass);
    }
}
