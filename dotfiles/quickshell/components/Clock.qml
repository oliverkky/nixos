import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import "." as Components

MouseArea {
    id: root

    required property var ui
    required property var parentWindow

    property date shownMonth: new Date(clock.date.getFullYear(), clock.date.getMonth(), 1)
    property bool expandedSurfaceReady: false
    readonly property var mediaPlayers: Mpris.players && Mpris.players.values ? Mpris.players.values : []
    readonly property var mediaPlayer: root.activeMediaPlayer()
    readonly property bool hasMediaPlayer: root.mediaPlayer !== null
    readonly property real pillProgress: calendar.visible ? calendar.progress : 0

    implicitWidth: clockText.implicitWidth + 34
    implicitHeight: 30
    width: implicitWidth
    height: implicitHeight
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: calendar.expanded = !calendar.expanded

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Rectangle {
        anchors.fill: parent
        radius: 999
        visible: opacity > 0
        opacity: Math.max(0, 1 - root.pillProgress * 1.4)
        color: root.containsMouse ? root.ui.panelSurfaceHover : root.ui.panelSurface
        border.width: 1
        border.color: root.ui.border
    }

    Text {
        id: clockText
        anchors.centerIn: parent
        visible: opacity > 0
        opacity: Math.max(0, 1 - root.pillProgress * 1.4)
        text: Qt.formatDateTime(clock.date, "hh:mm | ddd dd MMM yyyy")
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
        implicitHeight: root.hasMediaPlayer ? 441 : 357
        originX: Math.max(0, (implicitWidth - root.width) / 2)
        originY: 0
        originWidth: root.width
        originHeight: root.height
        expanded: false
        closeKey: expanded ? "calendar" : ""
        onCloseRequested: calendar.expanded = false
        onSurfaceOpened: root.expandedSurfaceReady = true
        onSurfaceClosed: root.expandedSurfaceReady = false

        Column {
            anchors.fill: parent
            spacing: 10

            Text {
                width: parent.width
                height: 28
                text: Qt.formatDateTime(clock.date, "hh:mm | dddd dd MMM yyyy")
                color: root.ui.text
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
                font.family: "Cantarell"
                font.pixelSize: 12
                font.weight: Font.Bold
                transform: Translate {
                    y: (1 - calendar.contentProgress) * -3
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: root.ui.borderSoft
            }

            Column {
                visible: root.hasMediaPlayer
                width: parent.width
                spacing: 8

                Row {
                    width: parent.width
                    height: 52
                    spacing: 10

                    Rectangle {
                        width: 44
                        height: 44
                        anchors.verticalCenter: parent.verticalCenter
                        radius: 10
                        color: root.ui.surface
                        border.width: 1
                        border.color: root.ui.borderSoft
                        clip: true

                        Image {
                            id: mediaArt

                            anchors.fill: parent
                            source: root.mediaArtUrl()
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: true
                            visible: source.toString().length > 0 && status !== Image.Error
                        }

                        Text {
                            anchors.centerIn: parent
                            visible: !mediaArt.visible
                            text: root.mediaPlayer && root.mediaPlayer.isPlaying ? "󰏤" : "󰐊"
                            color: root.ui.textMuted
                            font.family: "Symbols Nerd Font"
                            font.pixelSize: 18
                            font.weight: Font.Bold
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }

                    Column {
                        width: Math.max(0, parent.width - 190)
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 1

                        Text {
                            width: parent.width
                            text: root.mediaTitle()
                            color: root.ui.text
                            elide: Text.ElideRight
                            font.family: "Cantarell"
                            font.pixelSize: 12
                            font.weight: Font.Bold
                        }

                        Text {
                            width: parent.width
                            text: root.mediaSubtitle()
                            color: root.ui.textMuted
                            elide: Text.ElideRight
                            font.family: "Cantarell"
                            font.pixelSize: 11
                        }
                    }

                    IconButton {
                        ui: root.ui
                        icon: "󰒮"
                        enabled: root.mediaPlayer && root.mediaPlayer.canGoPrevious
                        opacity: enabled ? 1.0 : 0.35
                        onClicked: if (root.mediaPlayer)
                            root.mediaPlayer.previous()
                    }

                    IconButton {
                        ui: root.ui
                        icon: root.mediaPlayer && root.mediaPlayer.isPlaying ? "󰏤" : "󰐊"
                        enabled: root.mediaPlayer && root.mediaPlayer.canTogglePlaying
                        opacity: enabled ? 1.0 : 0.35
                        onClicked: if (root.mediaPlayer)
                            root.mediaPlayer.togglePlaying()
                    }

                    IconButton {
                        ui: root.ui
                        icon: "󰒭"
                        enabled: root.mediaPlayer && root.mediaPlayer.canGoNext
                        opacity: enabled ? 1.0 : 0.35
                        onClicked: if (root.mediaPlayer)
                            root.mediaPlayer.next()
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: root.ui.borderSoft
                }
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
                        property bool startsWeek: index % 7 === 0

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

                        Text {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.leftMargin: 3
                            anchors.topMargin: 2
                            visible: parent.startsWeek
                            text: root.isoWeekNumber(parent.day)
                            color: parent.isToday ? root.ui.background : root.ui.textMuted
                            opacity: parent.inMonth ? 0.75 : 0.35
                            font.family: "Cantarell"
                            font.pixelSize: 7
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

    function isoWeekNumber(date) {
        const target = new Date(date.getFullYear(), date.getMonth(), date.getDate());
        const day = (target.getDay() + 6) % 7;
        target.setDate(target.getDate() - day + 3);

        const firstThursday = new Date(target.getFullYear(), 0, 4);
        const firstThursdayDay = (firstThursday.getDay() + 6) % 7;
        firstThursday.setDate(firstThursday.getDate() - firstThursdayDay + 3);

        return 1 + Math.round((target - firstThursday) / 604800000);
    }

    function activeMediaPlayer() {
        for (let i = 0; i < mediaPlayers.length; i++) {
            if (mediaPlayers[i] && mediaPlayers[i].isPlaying)
                return mediaPlayers[i];
        }
        return mediaPlayers.length > 0 ? mediaPlayers[0] : null;
    }

    function mediaTitle() {
        if (!mediaPlayer)
            return "Media";

        return mediaPlayer.trackTitle || mediaPlayer.identity || "Media";
    }

    function mediaSubtitle() {
        if (!mediaPlayer)
            return "";

        return mediaPlayer.trackArtist || mediaPlayer.trackAlbum || mediaPlayer.identity || "";
    }

    function mediaArtUrl() {
        if (!mediaPlayer)
            return "";

        return mediaPlayer.trackArtUrl || "";
    }

    function openPopover() {
        calendar.expanded = true;
    }
}
