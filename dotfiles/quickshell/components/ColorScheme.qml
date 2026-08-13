import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    property string background: "#101014"
    property string foreground: "#e8e8ea"
    property string accent: "#8aa4ff"
    property string warning: "#d9a441"
    property string critical: "#e06c75"

    readonly property color text: foreground
    readonly property color textMuted: withAlpha(foreground, 0.62)
    readonly property color surface: withAlpha(foreground, 0.16)
    readonly property color surfaceHover: withAlpha(foreground, 0.24)
    readonly property color surfaceStrong: withAlpha(foreground, 0.90)
    readonly property color surfaceStrongHover: foreground
    readonly property color panelSurface: withAlpha(background, 0.74)
    readonly property color panelSurfaceHover: withAlpha(background, 0.84)
    readonly property color popoverSurface: withAlpha(background, 0.45)
    readonly property color border: withAlpha(foreground, 0.30)
    readonly property color borderBottom: withAlpha(foreground, 0.18)
    readonly property color borderSoft: withAlpha(foreground, 0.12)
    readonly property color shadow: withAlpha(background, 0.42)

    readonly property string cacheHome: Quickshell.env("XDG_CACHE_HOME") || `${Quickshell.env("HOME")}/.cache`
    readonly property string walPath: `${cacheHome}/wal/colors.json`

    property FileView walFile: FileView {
        id: walFile
        path: root.walPath
        blockLoading: true
        watchChanges: true
        printErrors: false

        onLoaded: root.loadWal()
        onFileChanged: reload()
    }

    Component.onCompleted: loadWal()

    function loadWal() {
        try {
            const parsed = JSON.parse(walFile.text());
            if (parsed.special) {
                root.background = parsed.special.background || root.background;
                root.foreground = parsed.special.foreground || root.foreground;
            }
            if (parsed.colors) {
                root.accent = parsed.colors.color4 || root.accent;
                root.warning = parsed.colors.color3 || root.warning;
                root.critical = parsed.colors.color1 || root.critical;
            }
        } catch (error) {
        }
    }

    function withAlpha(hex, alpha) {
        const value = normalize(hex);
        return Qt.rgba(
            parseInt(value.slice(1, 3), 16) / 255,
            parseInt(value.slice(3, 5), 16) / 255,
            parseInt(value.slice(5, 7), 16) / 255,
            alpha
        );
    }

    function normalize(hex) {
        if (!hex || hex.length < 7)
            return "#ffffff";
        return hex.charAt(0) === "#" ? hex : `#${hex}`;
    }
}
