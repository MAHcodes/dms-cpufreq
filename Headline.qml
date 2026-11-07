import QtQuick
import qs.Common
import qs.Widgets

// Filled tonal card: big value + caption, optional progress bar.
StyledRect {
    id: hl

    property string icon: ""
    property string value: ""
    property string caption: ""
    property real progress: -1          // 0..100, negative hides the bar

    height: col.implicitHeight + Theme.spacingM * 2
    radius: Theme.cornerRadius
    color: Theme.surfaceContainer

    Column {
        id: col
        x: Theme.spacingM
        y: Theme.spacingM
        width: parent.width - Theme.spacingM * 2
        spacing: Theme.spacingS

        Row {
            id: head
            width: parent.width
            spacing: Theme.spacingM

            Rectangle {
                width: 44
                height: 44
                radius: 22
                color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.14)

                DankIcon {
                    anchors.centerIn: parent
                    name: hl.icon
                    size: Theme.iconSize
                    color: Theme.primary
                }
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter

                StyledText {
                    text: hl.value
                    font.pixelSize: Theme.fontSizeLarge
                    font.weight: Font.Bold
                    color: Theme.surfaceText
                    elide: Text.ElideRight
                    width: Math.min(implicitWidth, head.width - 44 - Theme.spacingM)
                }
                StyledText {
                    text: hl.caption
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                    elide: Text.ElideRight
                    width: Math.min(implicitWidth, head.width - 44 - Theme.spacingM)
                }
            }
        }

        Meter {
            visible: hl.progress >= 0
            width: parent.width
            value: hl.progress
        }
    }
}
