import QtQuick
import qs.Common
import qs.Widgets

// Single-select control drawn like the power-profile buttons of the DMS /
// Material You 3 panels: separate pill buttons with a gap, the selected one
// filled with the primary color, the others tonal. Keeps the plugin-facing API
// (options / current / selected(value)).
Item {
    id: sc

    property var options: []            // strings, or { label, value, icon }
    property string current: ""
    property int maxPerRow: 5           // options per row before wrapping (5 options at 4 -> 3 + 2)

    signal selected(string value)

    function optLabel(o) { return typeof o === "string" ? o : o.label }
    function optValue(o) { return typeof o === "string" ? o : o.value }
    function optIcon(o) { return typeof o === "string" ? "" : (o.icon || "") }
    function onColor(c) { return c.hslLightness > 0.55 ? "#1c1b1f" : "#ffffff" }

    readonly property int gap: 8
    readonly property int n: options.length
    readonly property int perRow: n <= maxPerRow ? Math.max(1, n) : Math.ceil(n / Math.ceil(n / maxPerRow))
    readonly property int rows: n === 0 ? 0 : Math.ceil(n / perRow)
    readonly property int cellHeight: 48

    height: rows * cellHeight + Math.max(0, rows - 1) * gap

    Grid {
        id: grid
        width: parent.width
        columns: sc.perRow
        columnSpacing: sc.gap
        rowSpacing: sc.gap

        Repeater {
            model: sc.options

            delegate: Rectangle {
                id: btn
                readonly property bool active: sc.optValue(modelData) === sc.current
                readonly property string ico: sc.optIcon(modelData)
                readonly property color fg: active ? sc.onColor(Theme.primary) : Theme.surfaceText

                width: (grid.width - (sc.perRow - 1) * sc.gap) / sc.perRow
                height: sc.cellHeight
                radius: active ? height / 2 : 16
                color: active
                    ? Theme.primary
                    : Qt.tint(Theme.surfaceContainerHighest,
                              Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.14))

                Behavior on radius { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation { duration: 150 } }

                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    color: btn.fg
                    opacity: area.pressed ? 0.14 : (area.containsMouse ? 0.08 : 0)
                    Behavior on opacity { NumberAnimation { duration: 100 } }
                }

                Row {
                    id: content
                    anchors.centerIn: parent
                    spacing: Theme.spacingXS + 2
                    // drop the icon when the label would not fit next to it
                    readonly property bool showIcon: btn.ico !== ""
                        && btn.width >= lbl.implicitWidth + (Theme.iconSize - 6) + Theme.spacingL * 2 + 8

                    DankIcon {
                        visible: content.showIcon
                        name: btn.ico
                        size: Theme.iconSize - 6
                        color: btn.fg
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    StyledText {
                        id: lbl
                        text: sc.optLabel(modelData)
                        width: Math.min(implicitWidth, btn.width - Theme.spacingM * 2
                                        - (content.showIcon ? Theme.iconSize - 6 + Theme.spacingXS + 2 : 0))
                        elide: Text.ElideRight
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: Font.Medium
                        color: btn.fg
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    id: area
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: sc.selected(sc.optValue(modelData))
                }
            }
        }
    }
}
