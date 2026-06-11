import QtQuick
import Quickshell
import Quickshell as QS
import Quickshell.Wayland

QS.PopupWindow {
    id: root

    required property var ui
    property real originX: 0
    property real originY: 0
    property real originWidth: 1
    property real originHeight: 28
    readonly property int debugAnimationDuration: 1200
    readonly property int debugSurfaceReadyDelay: 80
    default property alias content: content.data
    signal surfaceOpened()
    signal surfaceClosed()

    color: "transparent"
    grabFocus: true

    BackgroundEffect.blurRegion: Region {
        item: surface
        radius: surface.radius
    }

    onVisibleChanged: {
        if (visible) {
            openAnimation.stop();
            surface.x = root.originX;
            surface.y = root.originY;
            surface.width = root.originWidth;
            surface.height = root.originHeight;
            surface.radius = root.originHeight / 2;
            openAnimation.start();
            openedTimer.restart();
        } else {
            openedTimer.stop();
            openAnimation.stop();
            surfaceClosed();
        }
    }

    Rectangle {
        id: surface

        x: 0
        y: 0
        width: root.implicitWidth
        height: root.implicitHeight
        radius: 16
        clip: true
        color: root.ui.panelSurface
        border.width: 1
        border.color: root.ui.border

        Item {
            id: content
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            anchors.topMargin: 0
            anchors.bottomMargin: 12
            clip: true
        }
    }

    ParallelAnimation {
        id: openAnimation

        NumberAnimation {
            target: surface
            property: "x"
            to: 0
            duration: root.debugAnimationDuration
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            target: surface
            property: "y"
            to: 0
            duration: root.debugAnimationDuration
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            target: surface
            property: "width"
            to: root.implicitWidth
            duration: root.debugAnimationDuration
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            target: surface
            property: "height"
            to: root.implicitHeight
            duration: root.debugAnimationDuration
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            target: surface
            property: "radius"
            to: 16
            duration: root.debugAnimationDuration
            easing.type: Easing.OutCubic
        }
    }

    Timer {
        id: openedTimer
        interval: root.debugSurfaceReadyDelay
        repeat: false
        onTriggered: root.surfaceOpened()
    }

}
