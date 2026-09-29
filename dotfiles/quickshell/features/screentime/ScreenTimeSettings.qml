import QtQuick
import "Model.js" as Model

Flickable {
    id: root

    required property var ui
    required property var service
    property int resetTodayClicks: 0
    property int wipeClicks: 0
    readonly property var storage: Model.storageSummary(service.days, service.months, service.years)

    contentWidth: width
    contentHeight: content.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    Timer {
        id: confirmationTimer
        interval: 5000
        repeat: false
        onTriggered: {
            root.resetTodayClicks = 0;
            root.wipeClicks = 0;
        }
    }

    Column {
        id: content
        width: root.width
        spacing: 16

        Text {
            text: "DAILY GOAL"
            color: root.ui.textMuted
            font.family: root.ui.typography.bodyFamily
            font.pixelSize: root.ui.typography.labelSize
            font.weight: Font.Bold
            font.letterSpacing: 1.2
        }

        Row {
            spacing: 8
            Repeater {
                model: Model.DAILY_GOAL_PRESETS
                Rectangle {
                    id: goalChip
                    required property int modelData
                    width: 74
                    height: 30
                    radius: root.ui.geometry.controlRadius
                    color: modelData === root.service.dailyGoalHours ? root.ui.surfaceStrong : root.ui.surface
                    border.width: 1
                    border.color: modelData === root.service.dailyGoalHours ? root.ui.accent : root.ui.borderSoft

                    Text {
                        anchors.centerIn: parent
                        text: goalChip.modelData === 0 ? "Off" : goalChip.modelData + " hours"
                        color: goalChip.modelData === root.service.dailyGoalHours ? root.ui.text : root.ui.textMuted
                        font.family: root.ui.typography.bodyFamily
                        font.pixelSize: root.ui.typography.labelSize
                        font.weight: Font.Bold
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.service.setDailyGoalHours(goalChip.modelData)
                    }
                }
            }
        }

        Text {
            text: "WEEKLY HISTORY"
            color: root.ui.textMuted
            font.family: root.ui.typography.bodyFamily
            font.pixelSize: root.ui.typography.labelSize
            font.weight: Font.Bold
            font.letterSpacing: 1.2
        }

        Row {
            spacing: 8
            Repeater {
                model: Model.WEEK_COUNT_OPTIONS
                Rectangle {
                    id: weekChip
                    required property int modelData
                    width: 74
                    height: 30
                    radius: root.ui.geometry.controlRadius
                    color: modelData === root.service.weekCount ? root.ui.surfaceStrong : root.ui.surface
                    border.width: 1
                    border.color: modelData === root.service.weekCount ? root.ui.accent : root.ui.borderSoft
                    Text {
                        anchors.centerIn: parent
                        text: weekChip.modelData + " weeks"
                        color: weekChip.modelData === root.service.weekCount ? root.ui.text : root.ui.textMuted
                        font.family: root.ui.typography.bodyFamily
                        font.pixelSize: root.ui.typography.labelSize
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.service.setWeekCount(weekChip.modelData)
                    }
                }
            }
        }

        Text {
            text: "TRACKING"
            color: root.ui.textMuted
            font.family: root.ui.typography.bodyFamily
            font.pixelSize: root.ui.typography.labelSize
            font.weight: Font.Bold
            font.letterSpacing: 1.2
        }

        Column {
            width: parent.width
            spacing: 6
            Text {
                text: "Ignored apps"
                color: root.ui.text
                font.family: root.ui.typography.bodyFamily
                font.pixelSize: root.ui.typography.bodySize
                font.weight: Font.Bold
            }
            Rectangle {
                width: parent.width
                height: 34
                radius: root.ui.geometry.controlRadius
                color: root.ui.surface
                border.width: ignoredInput.activeFocus ? 1 : 0
                border.color: root.ui.accent
                TextInput {
                    id: ignoredInput
                    anchors.fill: parent
                    anchors.margins: 9
                    text: root.service.ignoredAppsText
                    color: root.ui.text
                    selectByMouse: true
                    clip: true
                    font.family: root.ui.typography.bodyFamily
                    font.pixelSize: root.ui.typography.bodySize
                    onEditingFinished: root.service.setIgnoredApps(text)
                }
            }
            Text {
                text: "Comma-separated app IDs, for example discord, steam"
                color: root.ui.textMuted
                font.family: root.ui.typography.bodyFamily
                font.pixelSize: root.ui.typography.labelSize
            }
        }

        Column {
            width: parent.width
            spacing: 6
            Text {
                text: "App aliases"
                color: root.ui.text
                font.family: root.ui.typography.bodyFamily
                font.pixelSize: root.ui.typography.bodySize
                font.weight: Font.Bold
            }
            Rectangle {
                width: parent.width
                height: 34
                radius: root.ui.geometry.controlRadius
                color: root.ui.surface
                border.width: aliasesInput.activeFocus ? 1 : 0
                border.color: root.ui.accent
                TextInput {
                    id: aliasesInput
                    anchors.fill: parent
                    anchors.margins: 9
                    text: root.service.appAliasesText
                    color: root.ui.text
                    selectByMouse: true
                    clip: true
                    font.family: root.ui.typography.bodyFamily
                    font.pixelSize: root.ui.typography.bodySize
                    onEditingFinished: root.service.setAppAliases(text)
                }
            }
            Text {
                text: "Comma-separated pairs, for example code=work, zen=browser"
                color: root.ui.textMuted
                font.family: root.ui.typography.bodyFamily
                font.pixelSize: root.ui.typography.labelSize
            }
        }

        Text {
            text: "DATA"
            color: root.ui.textMuted
            font.family: root.ui.typography.bodyFamily
            font.pixelSize: root.ui.typography.labelSize
            font.weight: Font.Bold
            font.letterSpacing: 1.2
        }

        Text {
            width: parent.width
            text: Model.storageLabel(root.storage) + " · " + Model.fmt(root.storage.totalMs)
            color: root.ui.textMuted
            font.family: root.ui.typography.bodyFamily
            font.pixelSize: root.ui.typography.labelSize
        }

        Row {
            width: parent.width
            spacing: 8

            Rectangle {
                width: (parent.width - 8) / 2
                height: 34
                radius: root.ui.geometry.controlRadius
                color: resetMouse.containsMouse ? root.ui.surfaceHover : root.ui.surface
                border.width: 1
                border.color: root.resetTodayClicks > 0 ? root.ui.warning : root.ui.borderSoft
                Text {
                    anchors.centerIn: parent
                    text: root.resetTodayClicks === 0 ? "Reset today" : "Confirm " + root.resetTodayClicks + "/3"
                    color: root.resetTodayClicks > 0 ? root.ui.warning : root.ui.text
                    font.family: root.ui.typography.bodyFamily
                    font.pixelSize: root.ui.typography.labelSize
                    font.weight: Font.Bold
                }
                MouseArea {
                    id: resetMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.wipeClicks = 0;
                        root.resetTodayClicks++;
                        confirmationTimer.restart();
                        if (root.resetTodayClicks >= 3) {
                            root.service.resetToday();
                            root.resetTodayClicks = 0;
                            confirmationTimer.stop();
                        }
                    }
                }
            }

            Rectangle {
                width: (parent.width - 8) / 2
                height: 34
                radius: root.ui.geometry.controlRadius
                color: wipeMouse.containsMouse ? root.ui.surfaceHover : root.ui.surface
                border.width: 1
                border.color: root.wipeClicks > 0 ? root.ui.critical : root.ui.borderSoft
                Text {
                    anchors.centerIn: parent
                    text: root.wipeClicks === 0 ? "Wipe all history" : "Confirm " + root.wipeClicks + "/4"
                    color: root.wipeClicks > 0 ? root.ui.critical : root.ui.text
                    font.family: root.ui.typography.bodyFamily
                    font.pixelSize: root.ui.typography.labelSize
                    font.weight: Font.Bold
                }
                MouseArea {
                    id: wipeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.resetTodayClicks = 0;
                        root.wipeClicks++;
                        confirmationTimer.restart();
                        if (root.wipeClicks >= 4) {
                            root.service.resetAll();
                            root.wipeClicks = 0;
                            confirmationTimer.stop();
                        }
                    }
                }
            }
        }
    }
}
