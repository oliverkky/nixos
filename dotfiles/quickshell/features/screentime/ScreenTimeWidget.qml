import QtQuick
import "Model.js" as Model
import "../../shared/surfaces" as Surfaces

Item {
    id: root

    required property var ui
    required property var parentWindow
    required property var service
    signal opening

    readonly property var goal: Model.goalProgress(service.today.total, service.dailyGoalHours)
    readonly property bool goalReached: goal && goal.reached

    implicitWidth: capsule.implicitWidth
    implicitHeight: 30
    width: implicitWidth
    height: implicitHeight

    function openPopover() {
        screenTimePanel.page = "today";
        screenTimePanel.selectedDayKey = root.service.todayKey;
        root.opening();
        popover.expanded = true;
    }

    function togglePopover() {
        if (!popover.expanded)
            root.opening();
        popover.expanded = !popover.expanded;
    }

    function closePopover() {
        popover.expanded = false;
    }

    Rectangle {
        id: capsule
        implicitWidth: content.implicitWidth + 22
        width: implicitWidth
        height: 30
        radius: root.ui.geometry.pillRadius
        color: button.containsMouse ? root.ui.panelSurfaceHover : root.ui.panelSurface
        border.width: 1
        border.color: root.ui.border

        Row {
            id: content
            anchors.centerIn: parent
            spacing: 7

            Text {
                text: root.goalReached ? "" : "󰔟"
                color: root.goalReached ? root.ui.accent : root.ui.text
                font.family: root.ui.typography.iconFamily
                font.pixelSize: root.ui.typography.iconSize
                font.weight: Font.Bold
            }

            Text {
                visible: !root.service.barCompact
                text: root.service.ready ? root.service.barLabel : "--"
                color: root.ui.text
                font.family: root.ui.typography.bodyFamily
                font.pixelSize: root.ui.typography.labelSize
                font.weight: Font.Bold
            }
        }

        MouseArea {
            id: button
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: Qt.PointingHandCursor
            onClicked: mouse => {
                if (mouse.button === Qt.RightButton)
                    root.service.setBarCompact(!root.service.barCompact);
                else
                    root.togglePopover();
            }
        }
    }

    Surfaces.PopoverSurface {
        id: popover
        ui: root.ui
        anchor.window: root.parentWindow
        anchor.rect.x: Math.max(12, root.x + root.width - implicitWidth)
        anchor.rect.y: root.y
        implicitWidth: 430
        implicitHeight: 520
        originX: Math.max(0, implicitWidth - root.width)
        originY: 0
        originWidth: root.width
        originHeight: root.height
        closeKey: "screen-time"
        onCloseRequested: expanded = false
        onSurfaceOpened: {
            screenTimePanel.page = "today";
            screenTimePanel.selectedDayKey = root.service.todayKey;
        }

        ScreenTimePanel {
            id: screenTimePanel
            anchors.fill: parent
            ui: root.ui
            service: root.service
        }
    }
}
