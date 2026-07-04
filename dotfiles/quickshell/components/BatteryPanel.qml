import QtQuick
import Quickshell.Services.UPower

Column {
    id: root

    required property var ui
    property var battery: null
    property bool hasBattery: false
    property real batteryPercent: 0
    property string batteryDetail: ""
    property string batteryIcon: "󰂑"
    property bool brightnessAvailable: false
    property real brightnessPercent: 0
    property bool idleInhibited: false
    property bool powerProfilesAvailable: false
    property bool powerSaverActive: false
    property bool balancedActive: false
    property bool performanceActive: false
    property bool hasPerformanceProfile: false

    signal setBrightness(real value)
    signal toggleIdleInhibited
    signal setPowerProfile(string profile)

    spacing: 8

    PanelAction {
        width: parent.width
        ui: root.ui
        icon: root.batteryIcon
        text: root.hasBattery ? `${Math.round(root.batteryPercent)}% ${UPowerDeviceState.toString(root.battery.state)}` : "Battery"
        subtext: root.batteryDetail
        warning: root.hasBattery && root.batteryPercent < 30
    }

    Column {
        visible: root.brightnessAvailable
        width: parent.width
        spacing: 2

        Row {
            width: parent.width
            height: 18

            Text {
                width: parent.width - 48
                text: "Brightness"
                color: root.ui.text
                elide: Text.ElideRight
                font.family: "Cantarell"
                font.pixelSize: 12
                font.weight: Font.Bold
            }

            Text {
                width: 48
                text: `${Math.round(root.brightnessPercent)}%`
                color: root.ui.textMuted
                horizontalAlignment: Text.AlignRight
                font.family: "Cantarell"
                font.pixelSize: 11
            }
        }

        SliderRow {
            width: parent.width
            ui: root.ui
            icon: "󰃠"
            value: root.brightnessPercent
            maximum: 100
            onMoved: value => root.setBrightness(value)
        }
    }

    PanelAction {
        width: parent.width
        ui: root.ui
        icon: root.idleInhibited ? "󰅶" : "󰾪"
        text: root.idleInhibited ? "Idle inhibited" : "Idle allowed"
        subtext: root.idleInhibited ? "Lock and sleep timers are paused" : "Hypridle timers are active"
        active: root.idleInhibited
        onClicked: root.toggleIdleInhibited()
    }

    PanelAction {
        visible: root.powerProfilesAvailable
        width: parent.width
        ui: root.ui
        icon: "󰌪"
        text: "Power saver"
        active: root.powerSaverActive
        onClicked: root.setPowerProfile("power-saver")
    }

    PanelAction {
        visible: root.powerProfilesAvailable
        width: parent.width
        ui: root.ui
        icon: ""
        text: "Balanced"
        active: root.balancedActive
        onClicked: root.setPowerProfile("balanced")
    }

    PanelAction {
        visible: root.powerProfilesAvailable && root.hasPerformanceProfile
        width: parent.width
        ui: root.ui
        icon: ""
        text: "Performance"
        active: root.performanceActive
        onClicked: root.setPowerProfile("performance")
    }
}
