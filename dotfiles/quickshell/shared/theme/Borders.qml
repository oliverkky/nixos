import QtQuick

QtObject {
    required property var colors

    readonly property int width: 1
    readonly property color regular: colors.withAlpha(colors.foreground, 0.30)
    readonly property color bottom: colors.withAlpha(colors.foreground, 0.18)
    readonly property color soft: colors.withAlpha(colors.foreground, 0.12)
    readonly property color shadow: colors.withAlpha(colors.background, 0.42)
}
