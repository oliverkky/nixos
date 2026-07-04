pragma ComponentBehavior: Bound

import QtQuick
import Quickshell as QS
import Quickshell.Services.Notifications
import Quickshell.Wayland
import Quickshell.Widgets

QS.PanelWindow {
    id: root

    property var notifications: []

    anchors {
        top: true
        right: true
    }

    margins {
        top: 12
        right: 12
    }

    implicitWidth: 360
    implicitHeight: root.notifications.length > 0 ? Math.min(582, root.notifications.length * 118 - 8) : 1
    visible: root.notifications.length > 0
    exclusiveZone: 0
    aboveWindows: true
    focusable: false
    color: "transparent"

    WlrLayershell.namespace: "oliver.quickshell.notifications"

    ColorScheme {
        id: colorScheme
    }

    NotificationServer {
        id: notificationServer

        bodySupported: true
        bodyMarkupSupported: false
        actionsSupported: true
        imageSupported: true
        persistenceSupported: true

        onNotification: notification => {
            notification.tracked = true;
            root.addNotification(notification);
        }
    }

    Column {
        id: toastStack

        width: parent.width
        spacing: 8

        Repeater {
            model: root.notifications

            MouseArea {
                id: toast

                required property var modelData
                readonly property var notification: modelData
                readonly property int timeout: root.notificationTimeout(notification)

                width: root.width
                height: card.implicitHeight
                implicitHeight: card.implicitHeight
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                cursorShape: Qt.PointingHandCursor

                Component.onCompleted: resetTimer()
                onContainsMouseChanged: resetTimer()
                onTimeoutChanged: resetTimer()

                Connections {
                    target: toast.notification

                    function onClosed(reason) {
                        root.removeNotification(toast.notification);
                    }

                    function onSummaryChanged() {
                        toast.resetTimer();
                    }

                    function onBodyChanged() {
                        toast.resetTimer();
                    }

                    function onUrgencyChanged() {
                        toast.resetTimer();
                    }

                    function onExpireTimeoutChanged() {
                        toast.resetTimer();
                    }
                }

                Timer {
                    id: expireTimer

                    interval: Math.max(1, toast.timeout)
                    running: false
                    repeat: false

                    onTriggered: {
                        if (toast.notification)
                            toast.notification.expire();
                    }
                }

                Rectangle {
                    id: card

                    width: parent.width
                    implicitHeight: Math.max(110, content.implicitHeight + 28)
                    height: implicitHeight
                    radius: 8
                    color: colorScheme.panelSurface
                    border.width: 1
                    border.color: toast.notification && toast.notification.urgency === NotificationUrgency.Critical ? colorScheme.critical : colorScheme.borderSoft

                    Row {
                        id: content

                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                            margins: 14
                        }
                        spacing: 12

                        Item {
                            width: 40
                            height: 40
                            anchors.top: parent.top

                            Image {
                                id: notificationImage

                                anchors.fill: parent
                                source: root.notificationImageSource(toast.notification)
                                visible: source.toString().length > 0 && status !== Image.Error
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                mipmap: true
                            }

                            IconImage {
                                id: appIcon

                                anchors.fill: parent
                                source: root.notificationIconSource(toast.notification)
                                visible: !notificationImage.visible && source.toString().length > 0
                                asynchronous: true
                                mipmap: true
                            }

                            Rectangle {
                                anchors.fill: parent
                                radius: 8
                                visible: !notificationImage.visible && !appIcon.visible
                                color: colorScheme.surface

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰂚"
                                    color: colorScheme.text
                                    font.family: "Symbols Nerd Font"
                                    font.pixelSize: 20
                                }
                            }
                        }

                        Column {
                            width: parent.width - 52
                            spacing: 6

                            Row {
                                width: parent.width
                                spacing: 8

                                Text {
                                    width: parent.width - closeButton.width - parent.spacing
                                    text: root.notificationTitle(toast.notification)
                                    color: colorScheme.text
                                    elide: Text.ElideRight
                                    textFormat: Text.PlainText
                                    font.family: "Cantarell"
                                    font.pixelSize: 13
                                    font.weight: Font.Bold
                                }

                                MouseArea {
                                    id: closeButton

                                    width: 22
                                    height: 22
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: 6
                                        color: closeButton.containsMouse ? colorScheme.surfaceHover : "transparent"
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        text: "×"
                                        color: colorScheme.textMuted
                                        font.family: "Cantarell"
                                        font.pixelSize: 16
                                    }

                                    onClicked: mouse => {
                                        mouse.accepted = true;
                                        if (toast.notification)
                                            toast.notification.dismiss();
                                    }
                                }
                            }

                            Text {
                                width: parent.width
                                text: root.notificationBody(toast.notification)
                                visible: text.length > 0
                                color: colorScheme.textMuted
                                wrapMode: Text.WordWrap
                                maximumLineCount: 4
                                elide: Text.ElideRight
                                textFormat: Text.PlainText
                                font.family: "Cantarell"
                                font.pixelSize: 12
                                lineHeight: 1.12
                            }

                            Row {
                                width: parent.width
                                spacing: 6
                                visible: root.notificationActions(toast.notification).length > 0

                                Repeater {
                                    model: root.notificationActions(toast.notification)

                                    MouseArea {
                                        id: actionButton

                                        required property var modelData

                                        width: Math.min(120, Math.max(64, actionLabel.implicitWidth + 18))
                                        height: 26
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor

                                        Rectangle {
                                            anchors.fill: parent
                                            radius: 6
                                            color: actionButton.containsMouse ? colorScheme.surfaceHover : colorScheme.surface
                                        }

                                        Text {
                                            id: actionLabel

                                            anchors.centerIn: parent
                                            width: parent.width - 12
                                            text: actionButton.modelData ? actionButton.modelData.text : ""
                                            color: colorScheme.text
                                            elide: Text.ElideRight
                                            textFormat: Text.PlainText
                                            horizontalAlignment: Text.AlignHCenter
                                            font.family: "Cantarell"
                                            font.pixelSize: 11
                                            font.weight: Font.Bold
                                        }

                                        onClicked: mouse => {
                                            mouse.accepted = true;
                                            if (actionButton.modelData)
                                                actionButton.modelData.invoke();
                                            if (toast.notification)
                                                toast.notification.dismiss();
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                onClicked: mouse => {
                    if (!toast.notification)
                        return;

                    if (mouse.button === Qt.LeftButton) {
                        const action = root.defaultAction(toast.notification);
                        if (action)
                            action.invoke();
                    }

                    toast.notification.dismiss();
                }

                function resetTimer() {
                    if (toast.timeout > 0 && !toast.containsMouse)
                        expireTimer.restart();
                    else
                        expireTimer.stop();
                }
            }
        }
    }

    function addNotification(notification) {
        root.notifications = root.notifications.filter(item => item && item.id !== notification.id);
        root.notifications.unshift(notification);
        root.notifications = root.notifications.slice(0, 5);
    }

    function removeNotification(notification) {
        if (!notification)
            return;

        root.notifications = root.notifications.filter(item => item && item.id !== notification.id);
    }

    function notificationTimeout(notification) {
        if (!notification)
            return 0;

        const requested = Number(notification.expireTimeout);
        if (requested === 0 || notification.urgency === NotificationUrgency.Critical)
            return 0;
        if (requested > 0)
            return requested;

        return 5000;
    }

    function notificationTitle(notification) {
        if (!notification)
            return "";

        return notification.summary || notification.appName || "Notification";
    }

    function notificationBody(notification) {
        if (!notification)
            return "";

        return notification.body || "";
    }

    function notificationImageSource(notification) {
        if (!notification || !notification.image)
            return "";

        return notification.image.charAt(0) === "/" ? `file://${notification.image}` : notification.image;
    }

    function notificationIconSource(notification) {
        if (!notification)
            return "";

        const icon = String(notification.appIcon || notification.desktopEntry || "");
        if (icon.startsWith("/"))
            return `file://${icon}`;
        if (icon.includes(":"))
            return icon;

        return "";
    }

    function notificationActions(notification) {
        if (!notification || !notification.actions)
            return [];

        return notification.actions;
    }

    function defaultAction(notification) {
        const actions = notificationActions(notification);
        for (let i = 0; i < actions.length; i++) {
            if (actions[i].identifier === "default")
                return actions[i];
        }

        return null;
    }
}
