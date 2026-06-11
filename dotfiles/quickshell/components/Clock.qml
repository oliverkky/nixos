import QtQuick
import Quickshell
import "." as Components

MouseArea {
    id: root

    required property var ui
    required property var parentWindow

    property date shownMonth: new Date(clock.date.getFullYear(), clock.date.getMonth(), 1)
    property bool expandedSurfaceReady: false

    implicitWidth: clockText.implicitWidth + 32
    implicitHeight: 28
    width: implicitWidth
    height: implicitHeight
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: calendar.visible = !calendar.visible

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Rectangle {
        anchors.fill: parent
        radius: 999
        visible: !calendar.visible || !root.expandedSurfaceReady
        color: root.containsMouse ? root.ui.panelSurfaceHover : root.ui.panelSurface
        border.width: 1
        border.color: root.ui.border
    }

    Text {
        id: clockText
        anchors.centerIn: parent
        visible: !calendar.visible || !root.expandedSurfaceReady
        text: Qt.formatDateTime(clock.date, "hh:mm | dd MMM yyyy")
        color: root.ui.text
        font.family: "Cantarell"
        font.pixelSize: 12
        font.weight: Font.Bold
    }

    Components.PopoverSurface {
        id: calendar
        ui: root.ui
        anchor.window: root.parentWindow
        anchor.rect.x: root.x + root.width / 2 - implicitWidth / 2
        anchor.rect.y: root.y
        implicitWidth: 300
        implicitHeight: 345
        originX: Math.max(0, (implicitWidth - root.width) / 2)
        originY: 0
        originWidth: root.width
        originHeight: root.height
        visible: false
        onVisibleChanged: {
            if (!visible)
                root.expandedSurfaceReady = false;
        }
        onSurfaceOpened: root.expandedSurfaceReady = true
        onSurfaceClosed: root.expandedSurfaceReady = false

        Column {
            anchors.fill: parent
            spacing: 10

            Text {
                width: parent.width
                height: 28
                text: Qt.formatDateTime(clock.date, "hh:mm | dd MMM yyyy")
                color: root.ui.text
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
                font.family: "Cantarell"
                font.pixelSize: 12
                font.weight: Font.Bold
            }

            Rectangle {
                width: parent.width
                height: 1
                color: root.ui.borderSoft
            }

            Row {
                width: parent.width
                height: 28

                Text {
                    width: parent.width - 72
                    anchors.verticalCenter: parent.verticalCenter
                    text: Qt.formatDate(root.shownMonth, "MMMM yyyy")
                    color: root.ui.text
                    font.family: "Cantarell"
                    font.pixelSize: 13
                    font.weight: Font.Bold
                }

                IconButton {
                    ui: root.ui
                    icon: "󰅁"
                    onClicked: root.shiftMonth(-1)
                }

                IconButton {
                    ui: root.ui
                    icon: "󰅂"
                    onClicked: root.shiftMonth(1)
                }
            }

            Grid {
                width: parent.width
                columns: 7
                rowSpacing: 4
                columnSpacing: 4

                Repeater {
                    model: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

                    Text {
                        required property string modelData
                        width: (parent.width - 24) / 7
                        height: 20
                        text: modelData
                        color: root.ui.textMuted
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.family: "Cantarell"
                        font.pixelSize: 10
                        font.weight: Font.Bold
                    }
                }

                Repeater {
                    model: 42

                    Rectangle {
                        required property int index

                        property date day: root.dayForCell(index)
                        property bool inMonth: day.getMonth() === root.shownMonth.getMonth()
                        property bool isToday: root.sameDate(day, clock.date)

                        width: (parent.width - 24) / 7
                        height: 28
                        radius: 8
                        color: isToday ? root.ui.surfaceStrong : "transparent"
                        border.width: isToday ? 1 : 0
                        border.color: root.ui.border

                        Text {
                            anchors.centerIn: parent
                            text: parent.day.getDate()
                            color: parent.isToday ? root.ui.background : parent.inMonth ? root.ui.text : root.ui.textMuted
                            opacity: parent.inMonth ? 1.0 : 0.45
                            font.family: "Cantarell"
                            font.pixelSize: 12
                            font.weight: Font.Bold
                        }
                    }
                }
            }
        }
    }

    function shiftMonth(delta) {
        shownMonth = new Date(shownMonth.getFullYear(), shownMonth.getMonth() + delta, 1);
    }

    function dayForCell(index) {
        const first = new Date(shownMonth.getFullYear(), shownMonth.getMonth(), 1);
        const mondayOffset = (first.getDay() + 6) % 7;
        return new Date(shownMonth.getFullYear(), shownMonth.getMonth(), index - mondayOffset + 1);
    }

    function sameDate(left, right) {
        return left.getFullYear() === right.getFullYear()
            && left.getMonth() === right.getMonth()
            && left.getDate() === right.getDate();
    }
}
