import QtQuick
import Quickshell.Services.Pipewire

Column {
    id: root

    required property var ui
    property var sink: null
    property var source: null
    required property var outputDevices
    required property var inputDevices
    required property var volumeIcon
    required property var audioNodeIcon
    required property var audioNodeLabel

    signal openFallback

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
        onClicked: if (root.sink && root.sink.audio)
            root.sink.audio.muted = !root.sink.audio.muted
    }

    PanelAction {
        width: parent.width
        ui: root.ui
        icon: root.source && root.source.audio && root.source.audio.muted ? "󰍭" : "󰍬"
        text: root.source && root.source.audio && root.source.audio.muted ? "Unmute microphone" : "Mute microphone"
        onClicked: if (root.source && root.source.audio)
            root.source.audio.muted = !root.source.audio.muted
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
        model: root.outputDevices

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
        visible: root.inputDevices.length > 0
        width: parent.width
        text: "Input"
        color: root.ui.textMuted
        elide: Text.ElideRight
        font.family: "Cantarell"
        font.pixelSize: 11
        font.weight: Font.Bold
    }

    Repeater {
        model: root.inputDevices

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
        onClicked: root.openFallback()
    }
}
