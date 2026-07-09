import QtQuick
import Quickshell
import Quickshell.Widgets
import "." as Components

Components.PopoverSurface {
    id: root

    required property var parentWindow
    required property var activeTrayItem
    required property var rootMenu
    required property var modelValues
    required property var iconSource
    required property var titleProvider
    property real anchorX: 0
    property real anchorY: 0

    signal closeMenuRequested()

    anchor.window: root.parentWindow
    anchor.rect.x: root.anchorX
    anchor.rect.y: root.anchorY
    implicitWidth: 286
    implicitHeight: root.panelHeight()
    expanded: root.activeTrayItem !== null
    closeKey: root.activeTrayItem ? "tray" : ""

    onCloseRequested: root.closeMenuRequested()

    Column {
        width: parent.width
        height: parent.height
        spacing: 10

        Row {
            width: parent.width
            height: 28
            spacing: 10

            IconImage {
                visible: root.activeTrayItem && root.iconSource(root.activeTrayItem).length > 0
                anchors.verticalCenter: parent.verticalCenter
                width: 16
                height: 16
                source: root.iconSource(root.activeTrayItem)
                asynchronous: true
                mipmap: true
            }

            Text {
                width: parent.width - (root.activeTrayItem && root.iconSource(root.activeTrayItem).length > 0 ? 26 : 0)
                anchors.verticalCenter: parent.verticalCenter
                text: root.titleProvider()
                color: root.ui.text
                elide: Text.ElideRight
                font.family: "Cantarell"
                font.pixelSize: 13
                font.weight: Font.Bold
            }
        }

        Rectangle {
            width: parent.width
            height: 1
            color: root.ui.borderSoft
        }

        Flickable {
            width: parent.width
            height: Math.max(0, parent.height - 49)
            clip: true
            contentWidth: width
            contentHeight: trayMenuList.implicitHeight
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: trayMenuList

                width: parent.width
                spacing: 4

                Repeater {
                    model: root.modelValues(trayMenuOpener.children)

                    Loader {
                        required property var modelData
                        property var entry: modelData

                        width: parent.width
                        sourceComponent: modelData && modelData.isSeparator ? trayMenuSeparator : trayMenuAction
                    }
                }
            }
        }
    }

    QsMenuOpener {
        id: trayMenuOpener

        menu: root.rootMenu
    }

    Component {
        id: trayMenuSeparator

        Rectangle {
            width: parent.width
            height: 9
            color: "transparent"

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                height: 1
                color: root.ui.borderSoft
            }
        }
    }

    Component {
        id: trayMenuAction

        MouseArea {
            id: trayMenuButton

            property var modelData: parent ? parent.entry : null
            readonly property bool checked: modelData && modelData.checkState === Qt.Checked

            width: parent.width
            height: 32
            hoverEnabled: true
            enabled: modelData && modelData.enabled
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor

            Rectangle {
                anchors.fill: parent
                radius: 8
                color: trayMenuButton.containsMouse && trayMenuButton.enabled ? root.ui.surfaceHover : "transparent"
            }

            Row {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 10

                Item {
                    width: 18
                    height: parent.height

                    Text {
                        visible: trayMenuButton.modelData && trayMenuButton.modelData.buttonType !== QsMenuButtonType.None
                        anchors.centerIn: parent
                        text: trayMenuButton.modelData && trayMenuButton.modelData.buttonType === QsMenuButtonType.RadioButton ? (trayMenuButton.checked ? "●" : "") : (trayMenuButton.checked ? "✓" : "")
                        color: root.ui.text
                        font.family: "Cantarell"
                        font.pixelSize: 12
                        font.weight: Font.Bold
                    }
                }

                Text {
                    width: parent.width - 46 - submenuArrow.width
                    anchors.verticalCenter: parent.verticalCenter
                    text: trayMenuButton.modelData ? trayMenuButton.modelData.text : ""
                    color: trayMenuButton.enabled ? root.ui.text : root.ui.textMuted
                    elide: Text.ElideRight
                    font.family: "Cantarell"
                    font.pixelSize: 12
                    font.weight: Font.Bold
                    opacity: trayMenuButton.enabled ? 1 : 0.55
                }

                Text {
                    id: submenuArrow

                    width: 10
                    anchors.verticalCenter: parent.verticalCenter
                    visible: trayMenuButton.modelData && trayMenuButton.modelData.hasChildren
                    text: "›"
                    color: root.ui.textMuted
                    font.family: "Cantarell"
                    font.pixelSize: 16
                    font.weight: Font.Bold
                }
            }

            onClicked: {
                if (!trayMenuButton.modelData || !trayMenuButton.modelData.enabled)
                    return;

                if (trayMenuButton.modelData.hasChildren) {
                    const point = trayMenuButton.mapToItem(null, trayMenuButton.width, 0);
                    trayMenuButton.modelData.display(root, point.x, point.y);
                    return;
                }

                trayMenuButton.modelData.sendTriggered();
                root.closeMenuRequested();
            }
        }
    }

    function panelHeight() {
        const entries = root.modelValues(trayMenuOpener.children).length;
        return Math.min(432, Math.max(108, 63 + (entries * 36)));
    }
}
