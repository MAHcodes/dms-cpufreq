import QtQuick
import qs.Common
import qs.Widgets

// Pill tab strip (Material 3 expressive chips): the selected tab is a filled
// primary pill, the others are tonal pills. Scrolls sideways if the tabs do
// not fit. Keeps the plugin API:
// model [{ key, label, icon }], current (key), selected(key).
Item {
    id: tabs

    property var model: []              // [{ key, label, icon }]
    property string current: ""
    signal selected(string key)

    readonly property int gap: 8
    readonly property int pillHeight: 44

    height: pillHeight

    function onColor(c) { return c.hslLightness > 0.55 ? "#1c1b1f" : "#ffffff" }

    Flickable {
        id: flick
        anchors.fill: parent
        contentWidth: strip.width
        contentHeight: height
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.HorizontalFlick

        Row {
            id: strip
            spacing: tabs.gap
            // fill the strip when everything fits
            readonly property real share: tabs.model.length > 0
                ? (tabs.width - (tabs.model.length - 1) * tabs.gap) / tabs.model.length : 0

            Repeater {
                model: tabs.model

                delegate: Rectangle {
                    id: pill
                    readonly property bool active: modelData.key === tabs.current
                    readonly property color fg: active ? tabs.onColor(Theme.primary) : Theme.surfaceText

                    width: Math.max(content.implicitWidth + Theme.spacingM * 2 + 4, strip.share)
                    height: tabs.pillHeight
                    radius: active ? height / 2 : 16
                    color: active
                        ? Theme.primary
                        : Qt.tint(Theme.surfaceContainerHighest,
                                  Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12))

                    Behavior on radius { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        color: pill.fg
                        opacity: area.pressed ? 0.14 : (area.containsMouse ? 0.08 : 0)
                        Behavior on opacity { NumberAnimation { duration: 100 } }
                    }

                    Row {
                        id: content
                        anchors.centerIn: parent
                        spacing: Theme.spacingXS + 2

                        DankIcon {
                            visible: !!modelData.icon
                            name: modelData.icon || ""
                            size: Theme.iconSize - 6
                            color: pill.fg
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        StyledText {
                            text: modelData.label
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: Font.Medium
                            color: pill.fg
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        id: area
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: tabs.selected(modelData.key)
                    }
                }
            }
        }
    }
}
