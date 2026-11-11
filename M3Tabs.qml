import QtQuick
import qs.Common
import qs.Widgets

// Pill tab strip (Material 3 expressive chips): the selected tab is a filled
// primary pill, the others are tonal pills. When the tabs do not fit the strip
// overflows: scroll it with the mouse wheel, drag it, use the edge chevrons,
// or just select tabs — the selected pill always scrolls itself into view, so
// every tab stays reachable. Keeps the plugin API:
// model [{ key, label, icon }], current (key), selected(key).
Item {
    id: tabs

    property var model: []              // [{ key, label, icon }]
    property string current: ""
    signal selected(string key)

    readonly property int gap: 8
    readonly property int pillHeight: 44
    // true when the pills together are wider than the strip and need scrolling
    readonly property bool overflowing: strip.width > width + 1

    height: pillHeight

    function onColor(c) { return c.hslLightness > 0.55 ? "#1c1b1f" : "#ffffff" }

    // scroll the selected pill fully into view
    function revealCurrent() {
        if (!overflowing) {
            flick.contentX = 0
            return
        }
        for (let i = 0; i < model.length; i++) {
            if (model[i].key !== current)
                continue
            const pill = pills.itemAt(i)
            if (!pill)
                return
            if (pill.x < flick.contentX)
                flick.contentX = Math.max(0, pill.x - gap)
            else if (pill.x + pill.width > flick.contentX + width)
                flick.contentX = Math.min(strip.width - width, pill.x + pill.width - width + gap)
            return
        }
    }

    function scrollBy(amount) {
        flick.contentX = Math.max(0, Math.min(strip.width - width, flick.contentX + amount))
    }

    onCurrentChanged: Qt.callLater(revealCurrent)
    onModelChanged: Qt.callLater(revealCurrent)
    onWidthChanged: Qt.callLater(revealCurrent)
    Component.onCompleted: Qt.callLater(revealCurrent)

    Flickable {
        id: flick
        anchors.fill: parent
        contentWidth: strip.width
        contentHeight: height
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.HorizontalFlick
        // let drags fall through to surrounding scroll views when it all fits
        interactive: tabs.overflowing

        Row {
            id: strip
            spacing: tabs.gap
            // fill the strip when everything fits
            readonly property real share: tabs.model.length > 0
                ? (tabs.width - (tabs.model.length - 1) * tabs.gap) / tabs.model.length : 0

            Repeater {
                id: pills

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

    // mouse wheel scrolls the strip; accepts no buttons so clicks and drags
    // still reach the pills underneath
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        enabled: tabs.overflowing
        onWheel: wheel => {
            const d = wheel.angleDelta.x !== 0 ? wheel.angleDelta.x : wheel.angleDelta.y
            if (d === 0)
                return
            wheel.accepted = true
            tabs.scrollBy(-d)
        }
    }

    // edge chevrons, shown only while tabs are hidden on that side
    component EdgeChevron: Rectangle {
        id: chevron

        property bool leading: true

        readonly property bool more: leading
            ? flick.contentX > 1
            : flick.contentX < flick.contentWidth - flick.width - 1

        anchors.verticalCenter: parent.verticalCenter
        width: 28
        height: 28
        radius: height / 2
        visible: tabs.overflowing && more
        color: area.containsMouse || area.pressed
            ? Qt.tint(Theme.surfaceContainerHighest,
                      Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.25))
            : Qt.tint(Theme.surfaceContainerHighest,
                      Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12))

        DankIcon {
            anchors.centerIn: parent
            name: chevron.leading ? "chevron_left" : "chevron_right"
            size: 18
            color: Theme.surfaceText
        }

        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: tabs.scrollBy(chevron.leading ? -tabs.width * 0.7 : tabs.width * 0.7)
        }
    }

    EdgeChevron {
        anchors.left: parent.left
        leading: true
    }

    EdgeChevron {
        anchors.right: parent.right
        leading: false
    }
}
