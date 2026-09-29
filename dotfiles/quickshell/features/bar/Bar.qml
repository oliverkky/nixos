import QtQuick
import Quickshell
import Quickshell as QS
import Quickshell.Wayland
import "../../shared/theme" as Theme
import "../status" as Status
import "../screentime" as ScreenTime

QS.PanelWindow {
    id: root

    required property var shellRoot
    required property var screenTimeService
    property int barHeight: 36

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: barHeight
    exclusiveZone: barHeight
    aboveWindows: true
    color: "transparent"

    WlrLayershell.namespace: "oliver.quickshell"

    BackgroundEffect.blurRegion: Region {
        Region {
            item: workspaces
            radius: workspaces.height / 2
        }

        Region {
            item: clock
            radius: clock.height / 2
        }

        Region {
            item: privacyIndicator
            radius: privacyIndicator.height / 2
        }

        Region {
            item: statusArea
            radius: statusArea.height / 2
        }

        Region {
            item: screenTime
            radius: screenTime.height / 2
        }
    }

    Theme.Theme {
        id: theme
    }

    Connections {
        target: root.shellRoot

        function onOpenSystemMenu() {
            screenTime.closePopover();
            statusArea.openPowerMenu();
        }

        function onToggleStatusPanel(panelName) {
            screenTime.closePopover();
            statusArea.togglePanel(panelName);
        }

        function onOpenCalendarMedia() {
            screenTime.closePopover();
            clock.openPopover();
        }

        function onOpenScreenTime() {
            screenTime.openPopover();
        }

    }

    Item {
        anchors.fill: parent

        Workspaces {
            id: workspaces

            anchors.left: parent.left
            anchors.leftMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            ui: theme
        }

        Clock {
            id: clock

            anchors.centerIn: parent
            ui: theme
            parentWindow: root
        }

        PrivacyIndicator {
            id: privacyIndicator

            anchors.left: clock.right
            anchors.leftMargin: 6
            anchors.verticalCenter: clock.verticalCenter
            ui: theme
        }

        Status.StatusArea {
            id: statusArea

            anchors.right: parent.right
            anchors.rightMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            ui: theme
            parentWindow: root
        }

        ScreenTime.ScreenTimeWidget {
            id: screenTime

            anchors.right: statusArea.left
            anchors.rightMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            ui: theme
            parentWindow: root
            service: root.screenTimeService
            onOpening: {
                statusArea.activePanel = "";
                clock.closePopover();
            }
        }

    }
}
