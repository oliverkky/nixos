import QtQuick
import Quickshell.Services.SystemTray
import Quickshell.Widgets

Rectangle {
    id: root

    required property var ui
    required property var trayItems
    required property var parentWindow
    required property var iconSource
    required property var fallbackIcon
    required property var openMenu

    implicitWidth: trayRow.implicitWidth + 12
    implicitHeight: 28
    width: implicitWidth
    height: implicitHeight
    radius: 999
    color: trayMouse.containsMouse ? root.ui.panelSurfaceHover : root.ui.panelSurface
    border.width: 1
    border.color: root.ui.border

    MouseArea {
        id: trayMouse

        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
    }

    Row {
        id: trayRow

        anchors.centerIn: parent
        spacing: 2

        Repeater {
            model: root.trayItems

            MouseArea {
                id: trayButton

                required property var modelData

                implicitWidth: 26
                implicitHeight: 24
                width: implicitWidth
                height: implicitHeight
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton

                Rectangle {
                    anchors.fill: parent
                    radius: 8
                    color: trayButton.containsMouse ? root.ui.surfaceHover : "transparent"
                }

                IconImage {
                    id: trayIcon

                    anchors.centerIn: parent
                    width: 16
                    height: 16
                    source: root.iconSource(trayButton.modelData)
                    asynchronous: true
                    mipmap: true
                    opacity: trayButton.modelData && trayButton.modelData.status === Status.Passive ? 0.55 : 1
                }

                Text {
                    anchors.centerIn: parent
                    visible: !trayButton.modelData || trayIcon.source.toString().length === 0 || trayIcon.status === Image.Error
                    text: root.fallbackIcon(trayButton.modelData)
                    color: root.ui.textMuted
                    font.family: "Cantarell"
                    font.pixelSize: 16
                    font.weight: Font.Bold
                    verticalAlignment: Text.AlignVCenter
                }

                onClicked: mouse => {
                    if (!trayButton.modelData)
                        return;

                    if (mouse.button === Qt.RightButton) {
                        if (trayButton.modelData.hasMenu)
                            trayButton.openTrayMenu();
                    } else if (mouse.button === Qt.LeftButton && trayButton.modelData.hasMenu) {
                        trayButton.openTrayMenu();
                    } else if (mouse.button === Qt.MiddleButton) {
                        trayButton.modelData.secondaryActivate();
                    } else {
                        trayButton.modelData.activate();
                    }
                }

                onWheel: wheel => {
                    if (!trayButton.modelData)
                        return;

                    if (Math.abs(wheel.angleDelta.x) > Math.abs(wheel.angleDelta.y))
                        trayButton.modelData.scroll(wheel.angleDelta.x, true);
                    else
                        trayButton.modelData.scroll(wheel.angleDelta.y, false);
                }

                function openTrayMenu() {
                    if (!trayButton.modelData || !trayButton.modelData.hasMenu)
                        return;

                    const localPoint = trayButton.mapToItem(root, 0, 0);
                    if (root.openMenu(trayButton.modelData, localPoint.x, localPoint.y, trayButton.width, trayButton.height))
                        return;

                    const nativePoint = trayButton.mapToItem(null, trayButton.width / 2, trayButton.height);
                    trayButton.modelData.display(root.parentWindow, nativePoint.x, nativePoint.y);
                }
            }
        }
    }
}
