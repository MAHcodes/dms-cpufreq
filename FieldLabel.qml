import QtQuick
import qs.Common
import qs.Widgets

Row {
    id: fl

    property string icon: ""
    property string text: ""

    spacing: Theme.spacingS

    DankIcon {
        visible: fl.icon !== ""
        name: fl.icon
        size: Theme.iconSize - 8
        color: Theme.primary
        anchors.verticalCenter: parent.verticalCenter
    }
    StyledText {
        text: fl.text
        font.pixelSize: Theme.fontSizeSmall
        font.weight: Font.Bold
        color: Theme.surfaceVariantText
        anchors.verticalCenter: parent.verticalCenter
    }
}
