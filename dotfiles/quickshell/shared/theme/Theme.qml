import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    readonly property Colors colors: Colors {}
    readonly property Borders borders: Borders { colors: root.colors }
    readonly property Geometry geometry: Geometry {}
    readonly property Typography typography: Typography {}

    readonly property color background: colors.background
    readonly property color foreground: colors.foreground
    readonly property color accent: colors.accent
    readonly property color warning: colors.warning
    readonly property color critical: colors.critical
    readonly property color text: colors.text
    readonly property color textMuted: colors.textMuted
    readonly property color surface: colors.surface
    readonly property color surfaceHover: colors.surfaceHover
    readonly property color surfaceStrong: colors.surfaceStrong
    readonly property color surfaceStrongHover: colors.surfaceStrongHover
    readonly property color panelSurface: colors.panelSurface
    readonly property color panelSurfaceHover: colors.panelSurfaceHover
    readonly property color popoverSurface: colors.popoverSurface
    readonly property color border: borders.regular
    readonly property color borderBottom: borders.bottom
    readonly property color borderSoft: borders.soft
    readonly property color shadow: borders.shadow

    readonly property string cacheHome: Quickshell.env("XDG_CACHE_HOME") || `${Quickshell.env("HOME")}/.cache`
    readonly property string wallustPath: `${cacheHome}/wallust/colors.json`

    property FileView wallustFile: FileView {
        id: wallustFile
        path: root.wallustPath
        blockLoading: true
        watchChanges: true
        printErrors: false

        onLoaded: root.loadWallust()
        onFileChanged: reload()
    }

    Component.onCompleted: loadWallust()

    function loadWallust() {
        try {
            const parsed = JSON.parse(wallustFile.text());
            if (parsed.special) {
                root.colors.background = parsed.special.background || root.colors.background;
                root.colors.foreground = parsed.special.foreground || root.colors.foreground;
            }
            if (parsed.colors) {
                root.colors.accent = parsed.colors.color4 || root.colors.accent;
                root.colors.warning = parsed.colors.color3 || root.colors.warning;
                root.colors.critical = parsed.colors.color1 || root.colors.critical;
            }
        } catch (error) {
        }
    }

    function withAlpha(colorValue, alpha) {
        return colors.withAlpha(colorValue, alpha);
    }
}
