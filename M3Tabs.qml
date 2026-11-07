import QtQuick
import qs.Common
import qs.Widgets

// Material 3 primary tabs: icon over label, 3px indicator under the active tab.
Item {
    id: tabs

    property var model: []              // [{ key, label, icon }]
    property string current: ""
    signal selected(string key)

    height: 60

    Row {
        anchors.fill: parent

        Repeater {
            model: tabs.model

            delegate: Item {
                id: tab
                readonly property bool active: modelData.key === tabs.current

                width: tabs.model.length > 0 ? tabs.width / tabs.model.length : tabs.width
                height: tabs.height

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 4
                    radius: Theme.cornerRadius
                    color: Theme.primary
                    opacity: mouse.pressed ? 0.12 : (mouse.containsMouse ? 0.08 : 0)
                }

                Column {
                    anchors.centerIn: parent
                    spacing: 2

                    DankIcon {
                        name: modelData.icon
                        size: Theme.iconSize - 4
                        color: tab.active ? Theme.primary : Theme.surfaceVariantText
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    StyledText {
                        text: modelData.label
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: tab.active ? Font.Bold : Font.Normal
                        color: tab.active ? Theme.primary : Theme.surfaceVariantText
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }

                Rectangle {
                    visible: tab.active
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: Math.min(parent.width - 16, 40)
                    height: 3
                    radius: 1.5
                    color: Theme.primary
                }

                MouseArea {
                    id: mouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: tabs.selected(modelData.key)
                }
            }
        }
    }

    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: 1
        color: Theme.outlineStrong
        opacity: 0.4
    }
}
