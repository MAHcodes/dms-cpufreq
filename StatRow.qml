import QtQuick
import qs.Common
import qs.Widgets

// Two looks, same API:
//  * list row (default): leading icon bubble, label, trailing value, optional pill progress bar
//  * tile (`tile: true`): rounded tonal tile with a big centred value, label under it and a
//    thin progress bar, used for the per-core grids
Item {
    id: row

    property string icon: ""
    property string label: ""
    property string value: ""
    property real progress: -1          // 0..100, negative hides the bar
    property bool tile: false

    readonly property color tint: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.16)

    implicitHeight: tile ? tileCol.implicitHeight + Theme.spacingM * 2 : listCol.implicitHeight
    height: implicitHeight

    // ------------------------------------------------------------ tile ----
    Rectangle {
        visible: row.tile
        anchors.fill: parent
        radius: 20
        color: Theme.surfaceContainerHighest

        Column {
            id: tileCol
            x: Theme.spacingS
            y: Theme.spacingM
            width: parent.width - Theme.spacingS * 2
            spacing: 2

            StyledText {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: row.value
                elide: Text.ElideRight
                font.pixelSize: row.width < 110 ? Theme.fontSizeMedium : Theme.fontSizeLarge
                font.weight: Font.Bold
                color: Theme.primary
            }
            StyledText {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: row.label
                elide: Text.ElideRight
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceVariantText
            }
            Item { width: 1; height: 4; visible: row.progress >= 0 }
            Meter {
                visible: row.progress >= 0
                width: parent.width
                height: 6
                value: row.progress
                trackColor: Theme.surfaceContainer
            }
        }
    }

    // ------------------------------------------------------------ list ----
    Column {
        id: listCol
        visible: !row.tile
        width: parent.width
        spacing: 6

        Item {
            width: parent.width
            height: 36

            Row {
                id: left
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.spacingS

                Rectangle {
                    visible: row.icon !== ""
                    width: 28
                    height: 28
                    radius: 14
                    color: row.tint
                    anchors.verticalCenter: parent.verticalCenter

                    DankIcon {
                        anchors.centerIn: parent
                        name: row.icon
                        size: Theme.iconSize - 10
                        color: Theme.primary
                    }
                }
                StyledText {
                    id: labelText
                    // leave room for the value; implicitWidth keeps the full text, so
                    // valueText's width (which depends on this row) never loops back
                    width: Math.max(0, Math.min(implicitWidth,
                            row.width - valueText.implicitWidth - Theme.spacingM
                            - (row.icon !== "" ? 28 + Theme.spacingS : 0)))
                    elide: Text.ElideRight
                    text: row.label
                    font.pixelSize: Theme.fontSizeMedium
                    color: Theme.surfaceVariantText
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            StyledText {
                id: valueText
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: row.value
                font.pixelSize: Theme.fontSizeMedium
                font.weight: Font.Medium
                color: Theme.surfaceText
                width: Math.max(0, Math.min(implicitWidth, parent.width - left.width - Theme.spacingM))
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignRight
            }
        }

        Meter {
            visible: row.progress >= 0
            width: parent.width
            value: row.progress
        }
    }
}
