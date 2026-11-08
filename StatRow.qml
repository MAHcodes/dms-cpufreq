import QtQuick
import qs.Common
import qs.Widgets

// List item: leading icon, label, trailing value, optional progress bar.
Column {
    id: row

    property string icon: ""
    property string label: ""
    property string value: ""
    property real progress: -1          // 0..100, negative hides the bar

    spacing: 4

    Item {
        width: row.width
        height: 32

        Row {
            id: left
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.spacingS

            DankIcon {
                visible: row.icon !== ""
                name: row.icon
                size: Theme.iconSize - 8
                color: Theme.surfaceVariantText
                anchors.verticalCenter: parent.verticalCenter
            }
            StyledText {
                text: row.label
                font.pixelSize: Theme.fontSizeMedium
                color: Theme.surfaceText
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        StyledText {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: row.value
            font.pixelSize: Theme.fontSizeMedium
            color: Theme.surfaceVariantText
            width: Math.max(0, Math.min(implicitWidth, parent.width - left.width - Theme.spacingM))
            elide: Text.ElideRight
        }
    }

    Meter {
        visible: row.progress >= 0
        width: row.width
        value: row.progress
    }
}
