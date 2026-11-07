import QtQuick
import qs.Common
import qs.Widgets

// Material 3 single-select segmented button. More than `maxPerRow` options wrap
// onto additional rows (each row is its own segmented button).
Column {
    id: sc

    property var options: []            // strings, or { label, value, icon }
    property string current: ""
    property int maxPerRow: 4
    signal selected(string value)

    spacing: Theme.spacingXS

    function optLabel(o) { return typeof o === "string" ? o : o.label }
    function optValue(o) { return typeof o === "string" ? o : o.value }
    function optIcon(o) { return typeof o === "string" ? "" : (o.icon || "") }

    readonly property int perRow: options.length > 0
        ? Math.ceil(options.length / Math.ceil(options.length / maxPerRow))
        : 1
    readonly property var rows: {
        const out = []
        for (let i = 0; i < options.length; i += perRow) out.push(options.slice(i, i + perRow))
        return out
    }
    readonly property real segW: width / perRow

    Repeater {
        model: sc.rows

        delegate: Rectangle {
            id: rowRect
            readonly property var segs: modelData

            width: sc.segW * segs.length
            height: 40
            radius: height / 2
            color: "transparent"
            border.width: 1
            border.color: Theme.outlineStrong

            Row {
                anchors.fill: parent
                anchors.margins: 1

                Repeater {
                    model: rowRect.segs

                    delegate: Item {
                        id: seg
                        readonly property bool sel: sc.optValue(modelData) === sc.current
                        readonly property bool isFirst: index === 0
                        readonly property bool isLast: index === rowRect.segs.length - 1
                        readonly property color tonal: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.18)

                        width: (rowRect.width - 2) / rowRect.segs.length
                        height: rowRect.height - 2
                        clip: true

                        // selected fill: one rounded shape, extended past the inner edges and
                        // clipped to this segment, so only the outer ends are rounded
                        // (and the translucent color is never drawn twice)
                        Rectangle {
                            visible: seg.sel
                            x: seg.isFirst ? 0 : -height
                            width: seg.width + (seg.isFirst ? 0 : height) + (seg.isLast ? 0 : height)
                            height: seg.height
                            radius: height / 2
                            color: seg.tonal
                        }

                        // state layer
                        Rectangle {
                            anchors.fill: parent
                            color: Theme.surfaceText
                            opacity: mouse.pressed ? 0.12 : (mouse.containsMouse ? 0.06 : 0)
                        }

                        // divider
                        Rectangle {
                            visible: !seg.isFirst
                            width: 1
                            height: parent.height
                            color: Theme.outlineStrong
                        }

                        Row {
                            anchors.centerIn: parent
                            spacing: Theme.spacingXS

                            DankIcon {
                                visible: seg.sel || sc.optIcon(modelData) !== ""
                                name: seg.sel ? "check" : sc.optIcon(modelData)
                                size: Theme.iconSize - 8
                                color: seg.sel ? Theme.primary : Theme.surfaceVariantText
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            StyledText {
                                text: sc.optLabel(modelData)
                                font.pixelSize: Theme.fontSizeSmall
                                font.weight: seg.sel ? Font.Bold : Font.Normal
                                color: seg.sel ? Theme.surfaceText : Theme.surfaceVariantText
                                elide: Text.ElideRight
                                width: Math.min(implicitWidth, seg.width - Theme.iconSize - Theme.spacingS)
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            id: mouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: sc.selected(sc.optValue(modelData))
                        }
                    }
                }
            }
        }
    }
}
