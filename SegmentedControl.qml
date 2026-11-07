import QtQuick
import qs.Common
import qs.Widgets

// Material 3 single-select segmented button.
//  * selected segment: solid accent color (Theme.primary) with a check
//  * other segments: subtle tonal fill with the regular variant text color
//  * height follows the font size (never smaller than 40)
//  * up to 5 options share one row; 6+ wrap into evenly sized rows
//  * option icons only show when each segment is wide enough for them
Column {
    id: sc

    property var options: []            // strings, or { label, value, icon }
    property string current: ""
    property int maxPerRow: 5
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
    readonly property bool iconsFit: segW >= 110
    readonly property real iconPx: Theme.iconSize - 8

    FontMetrics {
        id: fm
        font.pixelSize: Theme.fontSizeSmall
        font.weight: Font.Bold
    }
    readonly property real segH: Math.max(40, Math.ceil(fm.height) + Theme.spacingM * 2)

    Repeater {
        model: sc.rows

        delegate: Rectangle {
            id: rowRect
            readonly property var segs: modelData

            width: sc.segW * segs.length
            height: sc.segH
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
                        readonly property bool prevSel: index > 0 && sc.optValue(rowRect.segs[index - 1]) === sc.current
                        readonly property bool isFirst: index === 0
                        readonly property bool isLast: index === rowRect.segs.length - 1
                        readonly property bool showIcon: seg.sel || (sc.iconsFit && sc.optIcon(modelData) !== "")

                        width: (rowRect.width - 2) / rowRect.segs.length
                        height: rowRect.height - 2
                        clip: true

                        // Fill for every segment: one rounded shape, extended past the inner edges
                        // and clipped to this segment, so only the outer ends are rounded.
                        //  selected: solid accent
                        //  others  : permanent subtle fill (the old hover tone), a bit stronger on hover/press
                        Rectangle {
                            x: seg.isFirst ? 0 : -height
                            width: seg.width + (seg.isFirst ? 0 : height) + (seg.isLast ? 0 : height)
                            height: seg.height
                            radius: height / 2
                            color: seg.sel ? Theme.primary : Theme.surfaceText
                            opacity: seg.sel ? 1 : (mouse.pressed ? 0.20 : (mouse.containsMouse ? 0.14 : 0.08))
                        }

                        // hover / press feedback on the selected segment
                        Rectangle {
                            visible: seg.sel
                            x: seg.isFirst ? 0 : -height
                            width: seg.width + (seg.isFirst ? 0 : height) + (seg.isLast ? 0 : height)
                            height: seg.height
                            radius: height / 2
                            color: Theme.primaryText
                            opacity: mouse.pressed ? 0.16 : (mouse.containsMouse ? 0.08 : 0)
                        }

                        // divider (hidden next to the selected segment, where it would sit on the accent fill)
                        Rectangle {
                            visible: !seg.isFirst && !seg.sel && !seg.prevSel
                            width: 1
                            height: parent.height
                            color: Theme.outlineStrong
                        }

                        Row {
                            anchors.centerIn: parent
                            spacing: Theme.spacingXS

                            DankIcon {
                                visible: seg.showIcon
                                name: seg.sel ? "check" : sc.optIcon(modelData)
                                size: sc.iconPx
                                color: seg.sel ? Theme.primaryText : Theme.surfaceVariantText
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            StyledText {
                                text: sc.optLabel(modelData)
                                font.pixelSize: Theme.fontSizeSmall
                                font.weight: seg.sel ? Font.Bold : Font.Normal
                                color: seg.sel ? Theme.primaryText : Theme.surfaceVariantText
                                elide: Text.ElideRight
                                width: Math.min(implicitWidth,
                                                seg.width - Theme.spacingS * 2
                                                - (seg.showIcon ? sc.iconPx + Theme.spacingXS : 0))
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
