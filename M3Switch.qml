import QtQuick
import qs.Common
import qs.Widgets

// Material 3 switch: 52x32 track, thumb grows and shows a check when on.
Item {
    id: sw

    property bool checked: false
    signal toggled(bool value)

    width: 52
    height: 32

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: sw.checked ? Theme.primary : Theme.surfaceContainerHighest
        border.width: sw.checked ? 0 : 2
        border.color: Theme.outlineStrong
        Behavior on color { ColorAnimation { duration: 150 } }
    }

    Rectangle {
        id: thumb
        width: sw.checked ? 24 : 16
        height: width
        radius: width / 2
        anchors.verticalCenter: parent.verticalCenter
        x: sw.checked ? sw.width - width - 4 : 8
        color: sw.checked ? Theme.surfaceContainerHighest : Theme.surfaceVariantText

        Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
        Behavior on width { NumberAnimation { duration: 150 } }

        DankIcon {
            visible: sw.checked
            anchors.centerIn: parent
            name: "check"
            size: 16
            color: Theme.primary
        }
    }

    // state layer
    Rectangle {
        width: 40
        height: 40
        radius: 20
        anchors.verticalCenter: thumb.verticalCenter
        anchors.horizontalCenter: thumb.horizontalCenter
        color: Theme.primary
        opacity: mouse.pressed ? 0.12 : (mouse.containsMouse ? 0.08 : 0)
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: sw.toggled(!sw.checked)
    }
}
