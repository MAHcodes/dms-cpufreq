import QtQuick
import qs.Common

// Material 3 linear progress indicator.
Rectangle {
    id: meter

    property real value: 0              // 0..100

    height: 4
    radius: 2
    color: Theme.surfaceContainerHighest

    Rectangle {
        width: parent.width * Math.max(0, Math.min(100, meter.value)) / 100
        height: parent.height
        radius: parent.radius
        color: Theme.primary

        Behavior on width { NumberAnimation { duration: 200 } }
    }
}
