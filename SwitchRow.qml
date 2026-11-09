import QtQuick
import qs.Common
import qs.Widgets
import qs.DCommon.Widgets as DCommon

// List item: leading icon, label, and DMS's Material You 3 switch (DToggle).
// Keeps the plugin API: icon / label / checked / toggled(value). The whole
// row toggles, like a Material list item with a trailing switch.
Item {
    id: r

    property string icon: ""
    property string label: ""
    property bool checked: false
    signal toggled(bool value)

    height: Math.max(48, sw.height)

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
            elide: Text.ElideRight
            width: Math.max(0, r.width - 70 - (r.icon !== "" ? Theme.iconSize - 4 + Theme.spacingM : 0))
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    DCommon.DToggle {
        id: sw
        hideText: true
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        checked: r.checked
        onToggled: value => r.toggled(value)
    }

    MouseArea {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.rightMargin: 70
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            sw.checked = !sw.checked
            r.toggled(sw.checked)
        }
    }
}
