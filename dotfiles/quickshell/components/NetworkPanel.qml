import QtQuick
import Quickshell.Networking

Column {
    id: root

    required property var ui
    required property var networks
    required property var iconForNetwork
    required property var securityLabel
    property bool wifiEnabled: false
    property string label: ""
    property bool connected: false
    property var passwordTarget: null
    property string passwordError: ""

    signal toggleWifi
    signal rescan
    signal connectNetwork(var network)
    signal submitPassword(string password)
    signal cancelPassword(var input)
    signal openFallback
    signal disconnectWifi

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
            text: root.label
            color: root.ui.text
            elide: Text.ElideRight
            font.family: "Cantarell"
            font.pixelSize: 13
            font.weight: Font.Bold
        }

        IconButton {
            ui: root.ui
            icon: root.wifiEnabled ? "󰖩" : "󰖪"
            label: root.wifiEnabled ? "On" : "Off"
            active: root.wifiEnabled
            compact: false
            onClicked: root.toggleWifi()
        }

        IconButton {
            ui: root.ui
            icon: "󰑓"
            onClicked: root.rescan()
        }
    }

    Flickable {
        id: wifiScroller

        width: parent.width
        height: Math.max(102, parent.height - networkHeader.height - (passwordPrompt.visible ? passwordPrompt.height + 8 : 0) - networkFallback.height - 32)
        clip: true
        contentWidth: width
        contentHeight: wifiList.implicitHeight
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: wifiList

            width: wifiScroller.width
            spacing: 8

            Repeater {
                model: root.networks

                PanelAction {
                    required property var modelData

                    width: parent.width
                    ui: root.ui
                    icon: root.iconForNetwork(modelData)
                    text: modelData.name || "Hidden network"
                    subtext: modelData.connected ? "Connected" : modelData.known ? "Known" : root.securityLabel(modelData)
                    active: modelData.connected
                    onClicked: {
                        if (modelData.known || modelData.security === WifiSecurityType.Open)
                            modelData.connect();
                        else
                            root.connectNetwork(modelData);
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
                Keys.onEscapePressed: root.cancelPassword(passwordInput)
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
                    onClicked: root.cancelPassword(passwordInput)
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
        onClicked: root.openFallback()
    }
}
