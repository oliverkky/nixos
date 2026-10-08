import QtQuick
import "Model.js" as Model
import "../../shared/controls" as Controls

Item {
    id: root

    required property var ui
    required property var service
    property string page: "today"
    property string selectedDayKey: service.todayKey
    property bool showAllApps: false

    readonly property var activeDay: selectedDayKey === service.todayKey ? service.today : (service.days[selectedDayKey] || Model.newDay())
    readonly property var appRows: Model.appList(activeDay)
    readonly property var groupedApps: Model.groupedApps(appRows, Model.DONUT_MAX_SLICES, Model.DONUT_MIN_PCT)
    readonly property var segments: Model.arcSegments(groupedApps)
    readonly property var sliceColors: Model.sliceColors(Math.max(1, groupedApps.length), String(ui.accent))
    readonly property int visibleAppCount: showAllApps ? appRows.length : Math.min(appRows.length, 6)
    readonly property int goalHours: Model.goalForDay(service.goalLog, selectedDayKey)
    readonly property var goal: Model.goalProgress(activeDay.total, goalHours)

    function selectDay(key) {
        root.selectedDayKey = key;
        root.showAllApps = false;
    }

    Column {
        anchors.fill: parent
        spacing: 10

        Row {
            width: parent.width
            height: 30

            Text {
                width: parent.width - navigation.implicitWidth
                anchors.verticalCenter: parent.verticalCenter
                text: root.page === "year" ? "Year in review" : root.page === "settings" ? "Screen time settings" : "Screen time"
                color: root.ui.text
                font.family: root.ui.typography.bodyFamily
                font.pixelSize: root.ui.typography.titleSize
                font.weight: Font.Bold
            }

            Row {
                id: navigation
                spacing: 3

                Controls.IconButton {
                    ui: root.ui
                    icon: "󰃭"
                    active: root.page === "today"
                    onClicked: root.page = "today"
                }
                Controls.IconButton {
                    ui: root.ui
                    icon: "󰃰"
                    active: root.page === "year"
                    onClicked: root.page = "year"
                }
                Controls.IconButton {
                    ui: root.ui
                    icon: ""
                    active: root.page === "settings"
                    onClicked: root.page = "settings"
                }
            }
        }

        Rectangle {
            width: parent.width
            height: 1
            color: root.ui.borderSoft
        }

        Item {
            width: parent.width
            height: parent.height - 41

            Column {
                visible: root.page === "today"
                width: parent.width
                spacing: 8

                Row {
                    width: parent.width
                    height: 188
                    spacing: 12

                    DonutChart {
                        id: donut
                        width: 176
                        height: 176
                        anchors.verticalCenter: parent.verticalCenter
                        ui: root.ui
                        segments: root.segments
                        sliceColors: root.sliceColors
                        centerLabel: Model.relativeDayLabel(root.selectedDayKey, root.service.todayKey)
                        totalMs: root.activeDay.total || 0
                    }

                    Item {
                        width: parent.width - donut.width - 12
                        height: parent.height

                        Flickable {
                            anchors.fill: parent
                            contentWidth: width
                            contentHeight: legend.implicitHeight
                            clip: true
                            boundsBehavior: Flickable.StopAtBounds

                            Column {
                                id: legend
                                width: parent.width
                                spacing: 8

                                Text {
                                    visible: root.appRows.length === 0
                                    text: root.service.ready ? "No activity yet" : "Loading history…"
                                    color: root.ui.textMuted
                                    font.family: root.ui.typography.bodyFamily
                                    font.pixelSize: root.ui.typography.bodySize
                                }

                                Repeater {
                                    model: root.appRows.slice(0, root.visibleAppCount)

                                    Item {
                                        id: legendRow
                                        required property var modelData
                                        required property int index
                                        width: legend.width
                                        height: 20

                                        Rectangle {
                                            width: 8
                                            height: 8
                                            radius: 4
                                            anchors.left: parent.left
                                            anchors.verticalCenter: parent.verticalCenter
                                            color: (legendRow.index < root.groupedApps.length - 1 || root.groupedApps.length === root.appRows.length ? root.sliceColors[legendRow.index] : root.sliceColors[root.groupedApps.length - 1]) || root.ui.accent
                                        }
                                        Text {
                                            x: 16
                                            width: parent.width - timeText.width - 24
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: Model.displayName(legendRow.modelData.app)
                                            color: root.ui.textMuted
                                            elide: Text.ElideRight
                                            font.family: root.ui.typography.bodyFamily
                                            font.pixelSize: root.ui.typography.labelSize
                                        }
                                        Text {
                                            id: timeText
                                            anchors.right: parent.right
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: Model.fmt(legendRow.modelData.ms)
                                            color: root.ui.text
                                            font.family: root.ui.typography.bodyFamily
                                            font.pixelSize: root.ui.typography.labelSize
                                            font.weight: Font.Bold
                                        }
                                    }
                                }

                                MouseArea {
                                    visible: root.appRows.length > 6
                                    width: parent.width
                                    height: 24
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.showAllApps = !root.showAllApps
                                    Text {
                                        anchors.centerIn: parent
                                        text: root.showAllApps ? "Show less" : "Show all " + root.appRows.length
                                        color: root.ui.accent
                                        font.family: root.ui.typography.bodyFamily
                                        font.pixelSize: root.ui.typography.labelSize
                                        font.weight: Font.Bold
                                    }
                                }
                            }
                        }
                    }
                }

                Item {
                    visible: root.goal !== null
                    width: parent.width
                    height: visible ? 30 : 0

                    Text {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        text: root.goal && root.goal.reached ? "Daily goal reached" : root.goal ? Model.fmt(root.goal.remainingMs) + " remaining" : ""
                        color: root.goal && root.goal.reached ? root.ui.accent : root.ui.textMuted
                        font.family: root.ui.typography.bodyFamily
                        font.pixelSize: root.ui.typography.labelSize
                    }
                    Text {
                        anchors.right: parent.right
                        anchors.top: parent.top
                        text: root.goal ? root.goal.pct + "%" : ""
                        color: root.ui.textMuted
                        font.family: root.ui.typography.bodyFamily
                        font.pixelSize: root.ui.typography.labelSize
                    }
                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        height: 4
                        radius: 2
                        color: root.ui.surface
                        Rectangle {
                            width: root.goal ? parent.width * root.goal.pct / 100 : 0
                            height: parent.height
                            radius: parent.radius
                            color: root.ui.accent
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: root.ui.borderSoft
                }

                WeekChart {
                    width: parent.width
                    ui: root.ui
                    service: root.service
                    selectedDayKey: root.selectedDayKey
                    onDaySelected: key => root.selectDay(key)
                }
            }

            YearOverview {
                visible: root.page === "year"
                anchors.fill: parent
                ui: root.ui
                service: root.service
            }

            ScreenTimeSettings {
                visible: root.page === "settings"
                anchors.fill: parent
                ui: root.ui
                service: root.service
            }
        }
    }
}
