import QtQuick
import qs.Common
import qs.Widgets

Column {
    id: sr

    property string icon: ""
    property string label: ""
    property string valueText: ""
    property real from: 0
    property real to: 1
    property real value: 0
    property real step: 1
    readonly property real shown: slider.shown
    signal released(real newValue)

    spacing: 0

    Item {
        width: sr.width
        height: 24

        Row {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.spacingS

            DankIcon {
                visible: sr.icon !== ""
                name: sr.icon
                size: Theme.iconSize - 8
                color: Theme.surfaceVariantText
                anchors.verticalCenter: parent.verticalCenter
            }
            StyledText {
                text: sr.label
                font.pixelSize: Theme.fontSizeMedium
                color: Theme.surfaceText
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        StyledText {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: sr.valueText
            font.pixelSize: Theme.fontSizeMedium
            color: Theme.surfaceVariantText
        }
    }

    M3Slider {
        id: slider
        width: sr.width
        from: sr.from
        to: sr.to
        value: sr.value
        step: sr.step
        valueText: sr.valueText
        onReleased: newValue => sr.released(newValue)
    }
}
