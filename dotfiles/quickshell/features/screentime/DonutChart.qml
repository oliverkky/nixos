import QtQuick
import "Model.js" as Model

Item {
    id: root

    required property var ui
    required property var segments
    required property var sliceColors
    property string centerLabel: "Today"
    property double totalMs: 0
    property int hoveredSlice: -1

    readonly property real strokeWidth: 18
    readonly property real ringRadius: width / 2 - strokeWidth / 2
    readonly property var hoveredSegment: hoveredSlice >= 0 && hoveredSlice < segments.length ? segments[hoveredSlice] : null

    implicitWidth: 176
    implicitHeight: 176
    width: implicitWidth
    height: implicitHeight

    function colorFor(index, alpha) {
        var value = String(root.sliceColors[index] || root.ui.accent).replace(/[#\s]/g, "");
        if (!/^[0-9a-fA-F]{6}$/.test(value))
            return Qt.rgba(root.ui.accent.r, root.ui.accent.g, root.ui.accent.b, alpha);
        return Qt.rgba(parseInt(value.slice(0, 2), 16) / 255, parseInt(value.slice(2, 4), 16) / 255, parseInt(value.slice(4, 6), 16) / 255, alpha);
    }

    function sliceAt(x, y) {
        var dx = x - width / 2;
        var dy = y - height / 2;
        var radius = Math.sqrt(dx * dx + dy * dy);
        if (radius < ringRadius - strokeWidth / 2 - 4 || radius > ringRadius + strokeWidth / 2 + 4)
            return -1;

        var degrees = Math.atan2(dy, dx) * 180 / Math.PI;
        if (degrees < -90)
            degrees += 360;
        for (var i = 0; i < segments.length; i++) {
            var start = segments[i].startAngle;
            var end = start + segments[i].sweepAngle;
            if (end <= 360 ? degrees >= start && degrees <= end : degrees >= start || degrees <= end - 360)
                return i;
        }
        return -1;
    }

    Canvas {
        id: canvas
        anchors.fill: parent

        onPaint: {
            var context = getContext("2d");
            context.reset();
            var cx = width / 2;
            var cy = height / 2;
            var radians = Math.PI / 180;

            if (!root.segments || root.segments.length === 0) {
                context.lineWidth = root.strokeWidth;
                context.strokeStyle = root.ui.withAlpha(root.ui.text, 0.1);
                context.beginPath();
                context.arc(cx, cy, root.ringRadius, 0, Math.PI * 2, false);
                context.stroke();
                return;
            }

            for (var i = 0; i < root.segments.length; i++) {
                var segment = root.segments[i];
                context.lineWidth = root.strokeWidth;
                context.lineCap = "round";
                context.strokeStyle = root.colorFor(i, root.hoveredSlice < 0 || root.hoveredSlice === i ? 1 : 0.22);
                context.beginPath();
                context.arc(cx, cy, root.ringRadius, segment.startAngle * radians, (segment.startAngle + segment.sweepAngle) * radians, false);
                context.stroke();
            }
        }

        Connections {
            target: root
            function onSegmentsChanged() {
                canvas.requestPaint();
            }
            function onSliceColorsChanged() {
                canvas.requestPaint();
            }
            function onHoveredSliceChanged() {
                canvas.requestPaint();
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        onPositionChanged: mouse => root.hoveredSlice = root.sliceAt(mouse.x, mouse.y)
        onContainsMouseChanged: if (!containsMouse)
            root.hoveredSlice = -1
    }

    Column {
        anchors.centerIn: parent
        width: parent.width * 0.58
        spacing: 3

        Text {
            width: parent.width
            text: root.hoveredSegment ? Model.displayName(root.hoveredSegment.app) : root.centerLabel
            color: root.ui.text
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignHCenter
            font.family: root.ui.typography.bodyFamily
            font.pixelSize: root.ui.typography.bodySize
            font.weight: Font.Bold
        }

        Text {
            width: parent.width
            text: Model.fmt(root.hoveredSegment ? root.hoveredSegment.ms : root.totalMs)
            color: root.ui.textMuted
            horizontalAlignment: Text.AlignHCenter
            font.family: root.ui.typography.bodyFamily
            font.pixelSize: root.ui.typography.labelSize
            font.weight: Font.Bold
        }
    }
}
