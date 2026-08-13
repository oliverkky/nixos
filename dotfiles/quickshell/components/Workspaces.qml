import QtQuick
import Quickshell.Hyprland

Row {
    id: root

    required property var ui

    spacing: 7
    height: 20

    property var workspaceList: modelValues(Hyprland.workspaces)
    property int focusedId: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1
    property var workspaceIds: buildWorkspaceIds()

    Component.onCompleted: initializeDisplayedWorkspaces()
    onWorkspaceIdsChanged: syncDisplayedWorkspaces()

    ListModel {
        id: displayedWorkspaces
    }

    Repeater {
        model: displayedWorkspaces

        Item {
            id: slot

            required property int workspaceId

            property var workspace: root.workspaceById(workspaceId)
            property bool present: root.containsId(root.workspaceIds, workspaceId)
            property bool ready: false
            property bool active: root.focusedId === workspaceId
            property bool occupied: workspace && root.modelValues(workspace.toplevels).length > 0
            property int indicatorWidth: active ? 36 : 20

            width: indicatorWidth
            height: 20
            anchors.verticalCenter: parent.verticalCenter
            opacity: present && ready ? active || occupied ? 1.0 : 0.72 : 0.0
            scale: present && ready ? 1.0 : 0.72

            Component.onCompleted: Qt.callLater(() => {
                ready = true;
            })

            Behavior on opacity {
                NumberAnimation {
                    duration: 140
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on scale {
                NumberAnimation {
                    duration: 140
                    easing.type: Easing.OutCubic
                }
            }

            Rectangle {
                id: indicator

                anchors.fill: parent
                height: 20
                radius: 999
                color: slot.active ? root.ui.surfaceStrong : slot.occupied ? root.ui.surface : root.ui.withAlpha(root.ui.foreground, 0.08)
                border.width: 1
                border.color: slot.active ? root.ui.withAlpha("#ffffff", 0.88) : root.ui.border

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
            }

            MouseArea {
                anchors.fill: parent
                anchors.margins: -6
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.switchToWorkspace(slot.workspaceId)
                onWheel: event => root.switchRelative(event.angleDelta.y > 0 ? -1 : 1)
            }
        }
    }

    Timer {
        id: pruneTimer
        interval: 150
        repeat: false
        onTriggered: root.pruneDisplayedWorkspaces()
    }

    function workspaceById(id) {
        for (let i = 0; i < workspaceList.length; i++) {
            if (workspaceList[i].id === id)
                return workspaceList[i];
        }
        return null;
    }

    function switchRelative(delta) {
        const currentIndex = Math.max(0, workspaceIds.indexOf(focusedId));
        const nextIndex = Math.max(0, Math.min(workspaceIds.length - 1, currentIndex + delta));
        switchToWorkspace(workspaceIds[nextIndex]);
    }

    function switchToWorkspace(id) {
        Hyprland.dispatch(`hl.dsp.focus({ workspace = ${id} })`);
    }

    function initializeDisplayedWorkspaces() {
        displayedWorkspaces.clear();
        for (let i = 0; i < workspaceIds.length; i++)
            displayedWorkspaces.append({ workspaceId: workspaceIds[i] });
    }

    function syncDisplayedWorkspaces() {
        let hasLeaving = false;

        for (let i = 0; i < workspaceIds.length; i++) {
            const id = workspaceIds[i];
            if (!displayedContainsId(id))
                insertDisplayedWorkspace(id);
        }

        for (let i = 0; i < displayedWorkspaces.count; i++) {
            if (!containsId(workspaceIds, displayedWorkspaces.get(i).workspaceId)) {
                hasLeaving = true;
                break;
            }
        }

        if (hasLeaving)
            pruneTimer.restart();
        else
            pruneTimer.stop();
    }

    function pruneDisplayedWorkspaces() {
        for (let i = displayedWorkspaces.count - 1; i >= 0; i--) {
            if (!containsId(workspaceIds, displayedWorkspaces.get(i).workspaceId))
                displayedWorkspaces.remove(i);
        }
    }

    function insertDisplayedWorkspace(id) {
        let index = displayedWorkspaces.count;
        for (let i = 0; i < displayedWorkspaces.count; i++) {
            if (displayedWorkspaces.get(i).workspaceId > id) {
                index = i;
                break;
            }
        }
        displayedWorkspaces.insert(index, { workspaceId: id });
    }

    function displayedContainsId(id) {
        for (let i = 0; i < displayedWorkspaces.count; i++) {
            if (displayedWorkspaces.get(i).workspaceId === id)
                return true;
        }
        return false;
    }

    function containsId(ids, id) {
        for (let i = 0; i < ids.length; i++) {
            if (ids[i] === id)
                return true;
        }
        return false;
    }

    function buildWorkspaceIds() {
        let highest = focusedId === 10 ? 4 : Math.max(4, focusedId);

        for (let i = 0; i < workspaceList.length; i++) {
            const workspace = workspaceList[i];
            if (workspace.id > highest && workspace.id < 10 && root.modelValues(workspace.toplevels).length > 0)
                highest = workspace.id;
        }

        const ids = [];
        for (let id = 1; id <= highest; id++)
            ids.push(id);

        if (focusedId === 10)
            ids.push(10);

        return ids;
    }

    function modelValues(model) {
        if (!model)
            return [];
        if (model.values)
            return model.values;
        return [];
    }
}
