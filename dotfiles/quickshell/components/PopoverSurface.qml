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
    property bool expanded: false
    property string closeKey: expanded ? "expanded" : ""
    property bool hidingAfterClose: false
    readonly property int debugAnimationDuration: 160
    readonly property int closeAnimationDuration: 120
    readonly property int debugSurfaceReadyDelay: debugAnimationDuration
    default property alias content: content.data
    signal surfaceOpened()
    signal surfaceClosed()
    signal closeRequested()

    color: "transparent"
    grabFocus: true

    BackgroundEffect.blurRegion: Region {
        item: surface
        radius: surface.radius
    }

    onExpandedChanged: {
        if (expanded)
            startOpenAnimation();
        else
            startCloseAnimation();
    }

    onVisibleChanged: {
        if (visible)
            return;

        openedTimer.stop();

        if (hidingAfterClose) {
            hidingAfterClose = false;
            if (!closeAnimation.running)
                surfaceClosed();
            return;
        }

        openAnimation.stop();
        closeAnimation.stop();

        if (expanded) {
            visible = true;
            closeRequested();
            return;
        }

        surfaceClosed();
    }

    onImplicitWidthChanged: syncOpenSurface()
    onImplicitHeightChanged: syncOpenSurface()
    onOriginXChanged: syncOpenSurface()
    onOriginYChanged: syncOpenSurface()

    function syncOpenSurface() {
        if (!visible || !expanded || openAnimation.running || closeAnimation.running)
            return;

        surface.x = 0;
        surface.y = 0;
        surface.width = root.implicitWidth;
        surface.height = root.implicitHeight;
        surface.radius = 16;
    }

    function startOpenAnimation() {
        closeAnimation.stop();
        openAnimation.stop();
        if (!visible)
            visible = true;

        surface.x = root.originX;
        surface.y = root.originY;
        surface.width = root.originWidth;
        surface.height = root.originHeight;
        surface.radius = root.originHeight / 2;
        openAnimation.start();
        openedTimer.restart();
    }

    function startCloseAnimation() {
        openedTimer.stop();
        openAnimation.stop();
        if (!visible) {
            surfaceClosed();
            return;
        }

        closeAnimation.start();
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
            focus: root.visible

            Keys.onEscapePressed: {
                root.closeRequested();
            }
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

    ParallelAnimation {
        id: closeAnimation

        onFinished: {
            if (!root.expanded) {
                root.hidingAfterClose = true;
                root.visible = false;
            }
        }

        NumberAnimation {
            target: surface
            property: "x"
            to: root.originX
            duration: root.closeAnimationDuration
            easing.type: Easing.InCubic
        }

        NumberAnimation {
            target: surface
            property: "y"
            to: root.originY
            duration: root.closeAnimationDuration
            easing.type: Easing.InCubic
        }

        NumberAnimation {
            target: surface
            property: "width"
            to: root.originWidth
            duration: root.closeAnimationDuration
            easing.type: Easing.InCubic
        }

        NumberAnimation {
            target: surface
            property: "height"
            to: root.originHeight
            duration: root.closeAnimationDuration
            easing.type: Easing.InCubic
        }

        NumberAnimation {
            target: surface
            property: "radius"
            to: root.originHeight / 2
            duration: root.closeAnimationDuration
            easing.type: Easing.InCubic
        }
    }

    Timer {
        id: openedTimer
        interval: root.debugSurfaceReadyDelay
        repeat: false
        onTriggered: root.surfaceOpened()
    }

}
