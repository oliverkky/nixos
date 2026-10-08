import QtQuick

QtObject {
    property color background: "#101014"
    property color foreground: "#e8e8ea"
    property color accent: "#8aa4ff"
    property color warning: "#d9a441"
    property color critical: "#e06c75"

    readonly property color text: foreground
    readonly property color textMuted: withAlpha(foreground, 0.62)
    readonly property color surface: withAlpha(foreground, 0.16)
    readonly property color surfaceHover: withAlpha(foreground, 0.24)
    readonly property color surfaceStrong: withAlpha(foreground, 0.90)
    readonly property color surfaceStrongHover: foreground
    readonly property color panelSurface: withAlpha(background, 0.52)
    readonly property color panelSurfaceHover: withAlpha(background, 0.64)
    readonly property color popoverSurface: withAlpha(background, 0.32)

    function withAlpha(colorValue, alpha) {
        if (typeof colorValue === "string") {
            const value = colorValue.charAt(0) === "#" ? colorValue : `#${colorValue}`;
            if (value.length >= 7) {
                return Qt.rgba(
                    parseInt(value.slice(1, 3), 16) / 255,
                    parseInt(value.slice(3, 5), 16) / 255,
                    parseInt(value.slice(5, 7), 16) / 255,
                    alpha
                );
            }
        }
        return Qt.rgba(colorValue.r, colorValue.g, colorValue.b, alpha);
    }
}
