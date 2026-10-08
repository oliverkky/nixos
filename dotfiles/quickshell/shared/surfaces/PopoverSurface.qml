import QtQuick
import Quickshell
import Quickshell as QS
import Quickshell.Hyprland
import Quickshell.Wayland

QS.PanelWindow {
    id: root

    required property var ui
    required property var sourceWindow
    property real panelX: 0
    property real panelY: 0
    property real originX: 0
    property real originY: 0
    property real originWidth: 1
    property real originHeight: 28
    property bool expanded: false
    // Some popovers have an element that exists in both their collapsed and
    // expanded states. Keep that element drawn while the surface grows so it
    // reads as one object moving into place, rather than two cross-fading
    // copies.
    property bool animateContent: true
    property real collapsedContentLeftMargin: 12
    property real collapsedContentRightMargin: 12
    property real collapsedContentTopMargin: 12
    property string closeKey: expanded ? "expanded" : ""
    property bool hidingAfterClose: false
    property real progress: 0
    readonly property real contentProgress: Math.max(0, Math.min(1, (progress - 0.12) / 0.88))
    readonly property int surfaceRadius: root.ui.geometry.popoverRadius
    readonly property int debugAnimationDuration: 180
    readonly property int closeAnimationDuration: 130
    default property alias content: content.data
    signal surfaceOpened()
    signal surfaceClosed()
    signal closeRequested()

    screen: sourceWindow ? sourceWindow.screen : null
    anchors {
        top: true
        left: true
    }
    margins {
        top: root.panelY
        left: root.panelX
    }
    exclusionMode: ExclusionMode.Ignore
    aboveWindows: true
    focusable: true
    visible: false
    color: "transparent"
    mask: Region { item: surface }
    WlrLayershell.namespace: "oliver.quickshell.popover"

    HyprlandFocusGrab {
        id: focusGrab

        windows: [root]
        active: root.expanded
        onCleared: {
            if (root.expanded)
                root.closeRequested();
        }
    }

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
        surface.radius = root.surfaceRadius;
        progress = 1;
    }

    function startOpenAnimation() {
        closeAnimation.stop();
        openAnimation.stop();

        surface.x = root.originX;
        surface.y = root.originY;
        surface.width = root.originWidth;
        surface.height = root.originHeight;
        surface.radius = root.originHeight / 2;
        progress = 0;

        if (!visible)
            visible = true;

        openAnimation.start();
    }

    function startCloseAnimation() {
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
        radius: root.surfaceRadius
        clip: true
        color: root.ui.popoverSurface
        border.width: root.ui.borders.width
        border.color: root.ui.border

        Item {
            id: content
            anchors.fill: parent
            anchors.leftMargin: root.collapsedContentLeftMargin + ((12 - root.collapsedContentLeftMargin) * root.progress)
            anchors.rightMargin: root.collapsedContentRightMargin + ((12 - root.collapsedContentRightMargin) * root.progress)
            anchors.topMargin: root.collapsedContentTopMargin + ((12 - root.collapsedContentTopMargin) * root.progress)
            anchors.bottomMargin: 12
            clip: true
            focus: root.visible
            opacity: root.animateContent ? root.contentProgress : 1
            transform: Translate {
                y: root.animateContent ? (1 - root.contentProgress) * -6 : 0
            }

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
            to: root.surfaceRadius
            duration: root.debugAnimationDuration
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            target: root
            property: "progress"
            to: 1
            duration: root.debugAnimationDuration
            easing.type: Easing.OutCubic
        }

        onFinished: {
            root.syncOpenSurface();
            root.surfaceOpened();
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

        NumberAnimation {
            target: root
            property: "progress"
            to: 0
            duration: root.closeAnimationDuration
            easing.type: Easing.InCubic
        }
    }

}
