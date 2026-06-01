import QtQuick
import Quickshell.Hyprland

Row {
    id: root

    required property var ui

    spacing: 8
    height: 16

    property var workspaceList: Hyprland.workspaces.values
    property int focusedId: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1

    Repeater {
        model: [1, 2, 3, 4]

        Rectangle {
            id: indicator

            required property int modelData

            property var workspace: root.workspaceById(modelData)
            property bool active: root.focusedId === modelData
            property bool occupied: workspace && workspace.toplevels.values.length > 0

            width: active ? 36 : 20
            height: 20
            radius: 999
            anchors.verticalCenter: parent.verticalCenter
            color: active ? root.ui.surfaceStrong : occupied ? root.ui.surface : root.ui.withAlpha(root.ui.foreground, 0.08)
            border.width: 1
            border.color: active ? root.ui.withAlpha("#ffffff", 0.88) : root.ui.border
            opacity: active || occupied ? 1.0 : 0.72

            Behavior on width {
                NumberAnimation {
                    duration: 140
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on color {
                ColorAnimation {
                    duration: 140
                    easing.type: Easing.OutCubic
                }
            }

            MouseArea {
                anchors.fill: parent
                anchors.margins: -6
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Hyprland.dispatch(`workspace ${indicator.modelData}`)
                onWheel: event => root.switchRelative(event.angleDelta.y > 0 ? -1 : 1)
            }
        }
    }

    function workspaceById(id) {
        for (let i = 0; i < workspaceList.length; i++) {
            if (workspaceList[i].id === id)
                return workspaceList[i];
        }
        return null;
    }

    function switchRelative(delta) {
        const next = Math.max(1, Math.min(4, focusedId + delta));
        Hyprland.dispatch(`workspace ${next}`);
    }
}
