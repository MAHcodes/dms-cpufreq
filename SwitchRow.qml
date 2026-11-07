import QtQuick
import qs.Common
import qs.Widgets

Item {
    id: r

    property string icon: ""
    property string label: ""
    property bool checked: false
    signal toggled(bool value)

    height: 48

    Row {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.spacingM

        DankIcon {
            visible: r.icon !== ""
            name: r.icon
            size: Theme.iconSize - 4
            color: r.checked ? Theme.primary : Theme.surfaceVariantText
            anchors.verticalCenter: parent.verticalCenter
        }
        StyledText {
            text: r.label
            font.pixelSize: Theme.fontSizeMedium
            color: Theme.surfaceText
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    M3Switch {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        checked: r.checked
        onToggled: value => r.toggled(value)
    }

    // whole row is clickable, like a Material list item with a trailing switch
    MouseArea {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.rightMargin: 60
        cursorShape: Qt.PointingHandCursor
        onClicked: r.toggled(!r.checked)
    }
}
