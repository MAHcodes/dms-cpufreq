import QtQuick
import qs.Common
import qs.Widgets

// Material 3 button: filled (accent), tonal (subtle fill, like the unselected
// segmented-control options) or outlined, with an optional leading icon.
// Height follows the font size like SegmentedControl, never below 40.
Item {
    id: btn

    property string text: ""
    property string icon: ""
    property string variant: "tonal"        // "filled" | "tonal" | "outlined"
    property bool danger: false
    signal clicked()

    // Theme.error is not guaranteed on every DMS version
    readonly property color errorColor: Theme.error !== undefined ? Theme.error : Theme.primary
    readonly property color accent: danger ? errorColor : Theme.primary
    readonly property bool filled: variant === "filled"
    readonly property color fg: filled ? (danger ? Theme.surface : Theme.primaryText)
                                       : (variant === "outlined" ? accent : (danger ? errorColor : Theme.surfaceText))

    FontMetrics {
        id: fm
        font.pixelSize: Theme.fontSizeSmall
        font.weight: Font.Bold
    }

    implicitHeight: Math.max(40, Math.ceil(fm.height) + Theme.spacingM * 2)
    implicitWidth: content.implicitWidth + Theme.spacingL * 2
    height: implicitHeight

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: btn.filled ? btn.accent : (btn.variant === "tonal" ? Theme.surfaceText : "transparent")
        opacity: btn.filled ? 1 : (btn.variant === "tonal"
                    ? (mouse.pressed ? 0.20 : (mouse.containsMouse ? 0.14 : 0.08)) : 1)
        border.width: btn.variant === "outlined" ? 1 : 0
        border.color: btn.variant === "outlined" ? Theme.outlineStrong : "transparent"
    }

    // hover / press state layer on filled and outlined buttons
    Rectangle {
        visible: btn.variant !== "tonal"
        anchors.fill: parent
        radius: height / 2
        color: btn.filled ? Theme.primaryText : btn.accent
        opacity: mouse.pressed ? 0.16 : (mouse.containsMouse ? 0.08 : 0)
    }

    Row {
        id: content
        anchors.centerIn: parent
        spacing: Theme.spacingXS

        DankIcon {
            visible: btn.icon !== ""
            name: btn.icon
            size: Theme.iconSize - 8
            color: btn.fg
            anchors.verticalCenter: parent.verticalCenter
        }
        StyledText {
            text: btn.text
            font.pixelSize: Theme.fontSizeSmall
            font.weight: Font.Bold
            color: btn.fg
            elide: Text.ElideRight
            width: Math.min(implicitWidth, btn.width - Theme.spacingL * 2
                            - (btn.icon !== "" ? Theme.iconSize - 8 + Theme.spacingXS : 0))
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: btn.clicked()
    }
}
