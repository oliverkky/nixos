import QtQuick
import Quickshell
import Quickshell.Widgets
import "." as Components

Components.PopoverSurface {
    id: root

    required property var parentWindow
    required property var activeTrayItem
    required property var rootMenu
    required property var iconSource
    required property var titleProvider
    property real anchorX: 0
    property real anchorY: 0

    signal closeMenuRequested()

    anchor.window: root.parentWindow
    anchor.rect.x: root.anchorX
    anchor.rect.y: root.anchorY
    implicitWidth: 286
    // DBusMenu entries arrive asynchronously for several tray apps. Size from
    // the stable delegate count and fixed row metrics instead of Column
    // implicitHeight/childrenRect, which can briefly collapse back to one row.
    implicitHeight: root.panelHeight()
    expanded: root.activeTrayItem !== null
    animateContent: false
    // Match the icon's position inside the 28px tray button at progress 0;
    // PopoverSurface interpolates these to its normal padding as it expands.
    collapsedContentLeftMargin: 6
    collapsedContentRightMargin: 6
    collapsedContentTopMargin: 0
    closeKey: root.activeTrayItem ? "tray" : ""

    property var menuStack: root.rootMenu ? [root.rootMenu] : []
    property var currentMenu: root.rootMenu
    property int selectedIndex: root.firstSelectableIndex()

    onCloseRequested: root.closeMenuRequested()
    onSelectedIndexChanged: root.ensureSelectedVisible()
    onRootMenuChanged: {
        root.menuStack = root.rootMenu ? [root.rootMenu] : [];
        root.currentMenu = root.rootMenu;
    }
    onExpandedChanged: {
        if (expanded)
            root.selectedIndex = root.firstSelectableIndex();
    }
    onSurfaceOpened: trayMenuContent.forceActiveFocus()

    Column {
        id: trayMenuContent

        width: parent.width
        height: parent.height
        spacing: 10
        focus: root.visible

        // The popup is focus-grabbed by the shell, which also makes this work
        // for menus opened from a keyboard shortcut (there is no pointer
        // serial then).
        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) {
                root.closeMenuRequested();
                event.accepted = true;
            } else if (event.key === Qt.Key_Up || event.key === Qt.Key_K) {
                root.moveSelection(-1);
                event.accepted = true;
            } else if (event.key === Qt.Key_Down || event.key === Qt.Key_J) {
                root.moveSelection(1);
                event.accepted = true;
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                root.activateSelected();
                event.accepted = true;
            } else if (event.key === Qt.Key_Right || event.key === Qt.Key_L) {
                root.openSelectedChild();
                event.accepted = true;
            } else if (event.key === Qt.Key_Left || event.key === Qt.Key_H) {
                root.goBack();
                event.accepted = true;
            }
        }

        Item {
            id: trayMenuHeader

            readonly property bool hasIcon: root.activeTrayItem && root.iconSource(root.activeTrayItem).length > 0

            width: parent.width
            height: 28

            Text {
                width: Math.max(0, parent.width - (trayMenuHeader.hasIcon ? 26 : 0))
                anchors.verticalCenter: parent.verticalCenter
                text: root.titleProvider()
                color: root.ui.text
                elide: Text.ElideRight
                font.family: "Cantarell"
                font.pixelSize: 13
                font.weight: Font.Bold
            }

            IconImage {
                visible: trayMenuHeader.hasIcon
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: 16
                height: 16
                source: root.iconSource(root.activeTrayItem)
                asynchronous: true
                mipmap: true
            }
        }

        Rectangle {
            width: parent.width
            height: 1
            color: root.ui.borderSoft
        }

        Flickable {
            id: trayMenuScroll

            width: parent.width
            height: Math.max(0, parent.height - 49)
            clip: true
            contentWidth: width
            // Column's implicit height is stale for some asynchronous
            // DBusMenu ObjectModels. childrenRect tracks the actual delegates
            // positioned in the list, including every scrollable entry.
            contentHeight: trayMenuList.childrenRect.height
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: trayMenuList

                width: parent.width
                spacing: 4

                Repeater {
                    id: trayMenuRepeater

                    // Keep the QAbstractListModel intact here. Converting its
                    // values to a QObjectList makes QML treat the list as one
                    // model value for DBusMenu implementations such as Steam.
                    model: trayMenuOpener.children

                    onCountChanged: {
                        root.selectedIndex = root.firstSelectableIndex();
                        root.ensureSelectedVisible();
                        root.syncOpenSurface();
                    }

                    MouseArea {
                        id: trayMenuButton

                        required property var modelData
                        required property int index
                        property int entryIndex: index
                        readonly property bool separator: modelData && modelData.isSeparator
                        readonly property bool checked: modelData && modelData.checkState === Qt.Checked

                        width: parent.width
                        height: separator ? 9 : 32
                        hoverEnabled: !separator
                        enabled: !separator && modelData && modelData.enabled
                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor

                        Rectangle {
                            anchors.fill: parent
                            visible: trayMenuButton.separator
                            color: "transparent"

                            Rectangle {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                height: 1
                                color: root.ui.borderSoft
                            }
                        }

                        Rectangle {
                            anchors.fill: parent
                            visible: !trayMenuButton.separator
                            radius: 8
                            color: (trayMenuButton.containsMouse || root.selectedIndex === trayMenuButton.entryIndex) && trayMenuButton.enabled ? root.ui.surfaceHover : "transparent"
                        }

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 10
                            visible: !trayMenuButton.separator

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
                            trayMenuContent.forceActiveFocus();
                            root.selectedIndex = trayMenuButton.entryIndex;
                            root.activateEntry(trayMenuButton.modelData);
                        }

                        onContainsMouseChanged: {
                            if (containsMouse && enabled)
                                root.selectedIndex = trayMenuButton.entryIndex;
                        }
                    }
                }
            }
        }
    }

    QsMenuOpener {
        id: trayMenuOpener

        menu: root.currentMenu
    }

    function panelHeight() {
        const listHeight = root.menuListHeight();
        const naturalHeight = Math.max(105, 73 + listHeight);
        const screenHeight = root.parentWindow && root.parentWindow.screen ? root.parentWindow.screen.height : 0;
        const barHeight = root.parentWindow && root.parentWindow.height ? root.parentWindow.height : 0;

        // 24px PopoverSurface vertical padding + 49px header/divider section.
        // Use the menu's full natural height whenever it fits. Only retain a
        // scroll area when the menu is genuinely taller than the space below
        // the bar, with a small margin so the rounded edge stays on-screen.
        const availableHeight = screenHeight > 0 ? Math.max(105, screenHeight - barHeight - 12) : naturalHeight;
        return Math.min(naturalHeight, availableHeight);
    }

    function menuListHeight() {
        const count = trayMenuRepeater.count;
        if (count <= 0)
            return 32;

        let height = Math.max(0, count - 1) * trayMenuList.spacing;
        for (let i = 0; i < count; i++) {
            const delegate = trayMenuRepeater.itemAt(i);
            const entry = delegate ? delegate.modelData : null;
            height += entry && entry.isSeparator ? 9 : 32;
        }
        return height;
    }

    function isSelectable(index) {
        const delegate = trayMenuRepeater.itemAt(index);
        const entry = delegate ? delegate.modelData : null;
        return !!entry && !entry.isSeparator && entry.enabled;
    }

    function firstSelectableIndex() {
        for (let i = 0; i < trayMenuRepeater.count; i++) {
            if (root.isSelectable(i))
                return i;
        }
        return -1;
    }

    function moveSelection(delta) {
        if (trayMenuRepeater.count === 0)
            return;

        let index = root.selectedIndex;
        for (let count = 0; count < trayMenuRepeater.count; count++) {
            index = (index + delta + trayMenuRepeater.count) % trayMenuRepeater.count;
            if (root.isSelectable(index)) {
                root.selectedIndex = index;
                root.ensureSelectedVisible();
                return;
            }
        }
    }

    function activateSelected() {
        if (root.selectedIndex < 0)
            return;
        const delegate = trayMenuRepeater.itemAt(root.selectedIndex);
        root.activateEntry(delegate ? delegate.modelData : null);
    }

    function openSelectedChild() {
        if (root.selectedIndex < 0)
            return;

        const delegate = trayMenuRepeater.itemAt(root.selectedIndex);
        const entry = delegate ? delegate.modelData : null;
        if (entry && entry.enabled && entry.hasChildren)
            root.openChildMenu(entry);
    }

    function activateEntry(entry) {
        if (!entry || !entry.enabled)
            return;

        if (entry.hasChildren) {
            root.openChildMenu(entry);
            return;
        }

        entry.triggered();
        root.closeMenuRequested();
    }

    function openChildMenu(entry) {
        if (!entry || !entry.enabled || !entry.hasChildren)
            return;

        // QsMenuEntry is itself a QsMenuHandle, so feeding it back into
        // the opener exposes its children without asking Qt to render a
        // native (and differently themed) submenu.
        root.menuStack = root.menuStack.concat([entry]);
        root.currentMenu = entry;
        root.selectedIndex = -1;
        trayMenuScroll.contentY = 0;
        entry.opened();
    }

    function goBack() {
        if (root.menuStack.length < 2) {
            root.closeMenuRequested();
            return;
        }

        const closingMenu = root.menuStack[root.menuStack.length - 1];
        if (closingMenu)
            closingMenu.closed();
        root.menuStack = root.menuStack.slice(0, -1);
        root.currentMenu = root.menuStack[root.menuStack.length - 1];
        root.selectedIndex = -1;
        trayMenuScroll.contentY = 0;
    }

    function ensureSelectedVisible() {
        if (root.selectedIndex < 0 || !trayMenuScroll || !trayMenuRepeater)
            return;

        const delegate = trayMenuRepeater.itemAt(root.selectedIndex);
        if (!delegate)
            return;

        const top = delegate.y;
        const bottom = top + delegate.height;
        const visibleTop = trayMenuScroll.contentY;
        const visibleBottom = visibleTop + trayMenuScroll.height;
        const maxY = Math.max(0, trayMenuScroll.contentHeight - trayMenuScroll.height);

        if (top < visibleTop)
            trayMenuScroll.contentY = Math.max(0, top);
        else if (bottom > visibleBottom)
            trayMenuScroll.contentY = Math.min(maxY, bottom - trayMenuScroll.height);
    }
}
