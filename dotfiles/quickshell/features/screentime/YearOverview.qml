import QtQuick
import "Model.js" as Model

Item {
    id: root

    required property var ui
    required property var service
    property int selectedYear: new Date().getFullYear()
    readonly property int currentYear: new Date().getFullYear()
    readonly property int firstYear: Model.firstDataYear(service.days, service.months, service.years)
    readonly property var summary: Model.yearSummary(service.days, service.months, service.years, selectedYear, service.todayKey)
    readonly property real maxMonth: {
        var maximum = 0;
        for (var i = 0; i < summary.months.length; i++)
            maximum = Math.max(maximum, summary.months[i].ms);
        return maximum;
    }

    implicitHeight: 390

    Row {
        id: yearHeader
        width: parent.width
        height: 42

        MouseArea {
            width: 34
            height: 34
            enabled: root.selectedYear > root.firstYear
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: root.selectedYear--
            Text {
                anchors.centerIn: parent
                text: ""
                color: parent.enabled ? root.ui.text : root.ui.textMuted
                font.family: root.ui.typography.iconFamily
            }
        }

        Column {
            width: parent.width - 68
            spacing: 1

            Text {
                width: parent.width
                text: root.selectedYear
                color: root.ui.text
                horizontalAlignment: Text.AlignHCenter
                font.family: root.ui.typography.bodyFamily
                font.pixelSize: 18
                font.weight: Font.Bold
            }
            Text {
                width: parent.width
                text: Model.fmt(root.summary.total)
                color: root.ui.textMuted
                horizontalAlignment: Text.AlignHCenter
                font.family: root.ui.typography.bodyFamily
                font.pixelSize: root.ui.typography.labelSize
            }
        }

        MouseArea {
            width: 34
            height: 34
            enabled: root.selectedYear < root.currentYear
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: root.selectedYear++
            Text {
                anchors.centerIn: parent
                text: ""
                color: parent.enabled ? root.ui.text : root.ui.textMuted
                font.family: root.ui.typography.iconFamily
            }
        }
    }

    Column {
        anchors.top: yearHeader.bottom
        anchors.topMargin: 10
        width: parent.width
        spacing: 8

        Repeater {
            model: root.summary.months

            Item {
                id: monthRow
                required property var modelData
                width: parent.width
                height: 19

                Text {
                    width: 28
                    anchors.verticalCenter: parent.verticalCenter
                    text: monthRow.modelData.label
                    color: root.ui.textMuted
                    font.family: root.ui.typography.bodyFamily
                    font.pixelSize: root.ui.typography.labelSize
                }

                Rectangle {
                    x: 38
                    width: parent.width - 86
                    height: 9
                    anchors.verticalCenter: parent.verticalCenter
                    radius: height / 2
                    color: root.ui.surface

                    Rectangle {
                        width: root.maxMonth > 0 ? parent.width * monthRow.modelData.ms / root.maxMonth : 0
                        height: parent.height
                        radius: parent.radius
                        color: root.selectedYear === root.currentYear && monthRow.modelData.month === new Date().getMonth() ? root.ui.accent : root.ui.textMuted
                    }
                }

                Text {
                    width: 40
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: monthRow.modelData.hours
                    color: root.ui.text
                    horizontalAlignment: Text.AlignRight
                    font.family: root.ui.typography.bodyFamily
                    font.pixelSize: root.ui.typography.labelSize
                }
            }
        }
    }
}
