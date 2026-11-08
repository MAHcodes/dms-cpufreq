import QtQuick
import qs.Common
import qs.Widgets

// Small section sub-heading inside a card: icon + small caps label, with an
// optional muted description underneath. Sits on the parent's full width so
// the description can wrap.
Column {
    id: fl

    property string icon: ""
    property string text: ""
    property string sub: ""

    width: parent ? parent.width : 0
    spacing: 2

    Row {
        spacing: Theme.spacingS

        DankIcon {
            visible: fl.icon !== ""
            name: fl.icon
            size: Theme.iconSize - 10
            color: Theme.primary
            anchors.verticalCenter: parent.verticalCenter
        }
        StyledText {
            text: fl.text
            font.pixelSize: Theme.fontSizeSmall
            font.weight: Font.Bold
            font.capitalization: Font.AllCaps
            font.letterSpacing: 0.8
            color: Theme.surfaceVariantText
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    StyledText {
        visible: fl.sub !== ""
        width: parent.width
        text: fl.sub
        wrapMode: Text.WordWrap
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        opacity: 0.8
    }
}
