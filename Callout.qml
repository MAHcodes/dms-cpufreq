import QtQuick
import qs.Common
import qs.Widgets

// Tonal info / warning / error banner. Accent colors are guarded because
// Theme.warning / Theme.error are not available on every DMS version.
StyledRect {
    id: co

    property string text: ""
    property string tone: "info"            // "info" | "warn" | "error"
    property string icon: tone === "error" ? "error" : (tone === "warn" ? "warning" : "info")

    readonly property color accent: tone === "error"
        ? (Theme.error !== undefined ? Theme.error : Theme.primary)
        : (tone === "warn" ? (Theme.warning !== undefined ? Theme.warning : Theme.primary) : Theme.primary)

    width: parent ? parent.width : 0
    height: row.implicitHeight + Theme.spacingM * 2
    radius: 20
    color: Qt.rgba(accent.r, accent.g, accent.b, 0.14)

    Row {
        id: row
        x: Theme.spacingM
        y: Theme.spacingM
        spacing: Theme.spacingS

        DankIcon {
            id: glyph
            name: co.icon
            size: Theme.iconSize - 6
            color: co.accent
        }
        StyledText {
            text: co.text
            width: co.width - Theme.spacingM * 2 - glyph.width - row.spacing
            wrapMode: Text.WordWrap
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.surfaceText
        }
    }
}
