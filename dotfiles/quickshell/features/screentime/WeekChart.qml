import QtQuick
import "Model.js" as Model

Item {
    id: root

    required property var ui
    required property var service
    property int weekOffset: 0
    property string selectedDayKey: ""
    readonly property var view: Model.weekView(service.days, service.todayKey, service.weekCount, weekOffset)
    readonly property var weekDays: view.week ? view.week.days : []
    readonly property real scaleMax: Math.max(view.max || 0, 4 * 3600000)

    signal daySelected(string dayKey)

    implicitHeight: 176

    Row {
        id: header
        width: parent.width
        height: 28

        MouseArea {
            width: 28
            height: 28
            enabled: root.weekOffset < root.service.weekCount - 1
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: root.weekOffset++

            Text {
                anchors.centerIn: parent
                text: ""
                color: parent.enabled ? root.ui.text : root.ui.textMuted
                opacity: parent.enabled ? 1 : 0.35
                font.family: root.ui.typography.iconFamily
                font.pixelSize: 12
            }
        }

        Text {
            width: parent.width - 56
            anchors.verticalCenter: parent.verticalCenter
            text: root.view.week ? Model.weekRangeLabel(root.view.week) : "No weekly data"
            color: root.ui.text
            horizontalAlignment: Text.AlignHCenter
            font.family: root.ui.typography.bodyFamily
            font.pixelSize: root.ui.typography.labelSize
            font.weight: Font.Bold
        }

        MouseArea {
            width: 28
            height: 28
            enabled: root.weekOffset > 0
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: root.weekOffset--

            Text {
                anchors.centerIn: parent
                text: ""
                color: parent.enabled ? root.ui.text : root.ui.textMuted
                opacity: parent.enabled ? 1 : 0.35
                font.family: root.ui.typography.iconFamily
                font.pixelSize: 12
            }
        }
    }

    Item {
        id: plot
        anchors.top: header.bottom
        anchors.topMargin: 8
        width: parent.width
        height: 112

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            y: parent.height / 2
            height: 1
            color: root.ui.borderSoft
        }

        Row {
            anchors.fill: parent
            spacing: 8

            Repeater {
                model: root.weekDays

                Item {
                    id: dayColumn
                    required property var modelData
                    width: (plot.width - 48) / 7
                    height: plot.height

                    Rectangle {
                        id: dayBar
                        width: Math.max(8, parent.width - 8)
                        height: dayColumn.modelData.isFuture ? 2 : Math.max(dayColumn.modelData.ms > 0 ? 5 : 2, (dayColumn.modelData.ms / root.scaleMax) * 84)
                        anchors.bottom: dayLabel.top
                        anchors.bottomMargin: 6
                        anchors.horizontalCenter: parent.horizontalCenter
                        radius: Math.min(4, width / 2)
                        color: dayColumn.modelData.key === root.selectedDayKey || dayColumn.modelData.isToday ? root.ui.accent : root.ui.textMuted
                        opacity: dayColumn.modelData.isFuture ? 0.15 : dayColumn.modelData.ms > 0 ? 0.9 : 0.25
                    }

                    Text {
                        id: dayLabel
                        anchors.bottom: parent.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: dayColumn.modelData.label
                        color: dayColumn.modelData.key === root.selectedDayKey ? root.ui.accent : root.ui.textMuted
                        font.family: root.ui.typography.bodyFamily
                        font.pixelSize: root.ui.typography.labelSize
                        font.weight: dayColumn.modelData.isToday ? Font.Bold : Font.Normal
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: !dayColumn.modelData.isFuture
                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: root.daySelected(dayColumn.modelData.key)
                    }
                }
            }
        }
    }

    Text {
        anchors.top: plot.bottom
        anchors.topMargin: 4
        width: parent.width
        text: "Week total  " + Model.fmt(root.view.totalMs)
        color: root.ui.textMuted
        horizontalAlignment: Text.AlignHCenter
        font.family: root.ui.typography.bodyFamily
        font.pixelSize: root.ui.typography.labelSize
    }
}
