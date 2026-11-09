import QtQuick
import qs.Common

// Material 3 linear progress indicator: thick pill track, rounded fill.
Rectangle {
    id: meter

    property real value: 0              // 0..100
    property color trackColor: Theme.surfaceContainerHighest
    property color fillColor: Theme.primary

    height: 8
    radius: height / 2
    color: trackColor

    Rectangle {
        width: Math.max(parent.height, parent.width * Math.max(0, Math.min(100, meter.value)) / 100)
        height: parent.height
        radius: parent.radius
        color: meter.fillColor
        visible: meter.value > 0

        Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
    }
}
