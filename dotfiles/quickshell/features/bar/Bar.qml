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
    readonly property var notificationAvoidRects: [
        clock.occupyingExpandedArea ? clock.expandedRect : null,
        screenTime.occupyingExpandedArea ? screenTime.expandedRect : null,
        statusArea.occupyingExpandedArea ? statusArea.expandedRect : null,
        statusArea.trayMenuOccupyingExpandedArea ? statusArea.trayMenuExpandedRect : null
    ].filter(rect => rect !== null)
    readonly property real screenTimeClearance: Math.max(
        6,
        statusArea.occupyingExpandedArea ? statusArea.x - statusArea.expandedRect.x + 8 : 6,
        statusArea.trayMenuOccupyingExpandedArea ? statusArea.x - statusArea.trayMenuExpandedRect.x + 8 : 6
    )

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: barHeight
    exclusiveZone: barHeight
    aboveWindows: true
    color: "transparent"
    // This window is stacked above the persistent pill windows. Let pointer
    // events pass through its empty clock, status, and screen-time slots.
    mask: Region {
        Region { item: workspaces }
    }

    WlrLayershell.namespace: "oliver.quickshell"

    BackgroundEffect.blurRegion: Region {
        Region {
            item: workspaces
            radius: workspaces.height / 2
        }

        Region {
            item: privacyIndicator
            radius: privacyIndicator.height / 2
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
            onOpening: {
                screenTime.closePopover();
                statusArea.activePanel = "";
                statusArea.closeTrayMenu();
            }
        }

        PrivacyIndicator {
            id: privacyIndicator

            anchors.left: clock.right
            anchors.leftMargin: clock.occupyingExpandedArea
                ? Math.max(6, clock.expandedRect.x + clock.expandedRect.width - clock.x - clock.width + 6)
                : 6
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
            onOpening: {
                screenTime.closePopover();
                clock.closePopover();
            }
        }

        ScreenTime.ScreenTimeWidget {
            id: screenTime

            anchors.right: statusArea.left
            anchors.rightMargin: root.screenTimeClearance
            anchors.verticalCenter: parent.verticalCenter
            ui: theme
            parentWindow: root
            service: root.screenTimeService
            onOpening: {
                statusArea.activePanel = "";
                statusArea.closeTrayMenu();
                clock.closePopover();
            }
        }

    }
}
