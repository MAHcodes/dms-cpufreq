import QtQuick
import qs.Common
import qs.Widgets

// Pill action button: text / icon / variant ("filled" | "tonal" | "outlined") / danger,
// with a hover / press state layer. `clicked` fires on tap.
Item {
    id: btn

    property string text: ""
    property string icon: ""
    property string variant: "tonal"
    property bool danger: false

    signal clicked()

    function onColor(c) { return c.hslLightness > 0.55 ? "#1c1b1f" : "#ffffff" }

    readonly property color accent: danger && Theme.error !== undefined ? Theme.error : Theme.primary
    readonly property color fillColor: variant === "filled"
        ? accent
        : variant === "tonal"
            ? Qt.tint(Theme.surfaceContainerHighest, Qt.rgba(accent.r, accent.g, accent.b, 0.18))
            : "transparent"
    readonly property color fg: variant === "filled" ? onColor(accent) : accent

    implicitHeight: 48
    implicitWidth: content.implicitWidth + Theme.spacingXL * 2
    height: 48
    opacity: enabled ? 1 : 0.45

    Rectangle {
        id: bg
        anchors.fill: parent
        radius: area.pressed ? 16 : height / 2
        color: btn.fillColor
        border.width: btn.variant === "outlined" ? 1 : 0
        border.color: Qt.rgba(Theme.surfaceVariantText.r, Theme.surfaceVariantText.g,
                              Theme.surfaceVariantText.b, 0.4)

        Behavior on radius { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
        Behavior on color { ColorAnimation { duration: 150 } }

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: btn.fg
            opacity: area.pressed ? 0.14 : (area.containsMouse ? 0.08 : 0)
            Behavior on opacity { NumberAnimation { duration: 100 } }
        }
    }

    Row {
        id: content
        anchors.centerIn: parent
        spacing: Theme.spacingS
        width: Math.min(implicitWidth, btn.width - Theme.spacingM * 2)

        DankIcon {
            visible: btn.icon !== ""
            name: btn.icon
            size: Theme.iconSize - 6
            color: btn.fg
            anchors.verticalCenter: parent.verticalCenter
        }
        StyledText {
            text: btn.text
            width: Math.min(implicitWidth, btn.width - Theme.spacingM * 2
                            - (btn.icon !== "" ? Theme.iconSize - 6 + Theme.spacingS : 0))
            elide: Text.ElideRight
            font.pixelSize: Theme.fontSizeMedium
            font.weight: Font.Medium
            color: btn.fg
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        enabled: btn.enabled
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: btn.clicked()
    }
}
