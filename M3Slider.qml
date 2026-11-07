import QtQuick
import qs.Common
import qs.Widgets

// Material 3 slider. Emits `released` once when the user lets go: changing CPU
// limits needs a privileged helper call, so committing on every tick is not an option.
Item {
    id: s

    property real from: 0
    property real to: 1
    property real value: 0
    property real step: 1
    property string valueText: ""        // shown in a bubble while dragging
    signal released(real newValue)

    property bool dragging: false
    property bool holding: false         // keep the dragged value until the next poll lands
    property real dragValue: 0

    readonly property real shown: (dragging || holding) ? dragValue : value
    readonly property real frac: to > from ? Math.max(0, Math.min(1, (shown - from) / (to - from))) : 0
    readonly property real handle: 20

    height: 40

    onValueChanged: holding = false

    Timer {
        id: holdTimer
        interval: 4000
        onTriggered: s.holding = false
    }

    Rectangle {                               // inactive track
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 4
        radius: 2
        color: Theme.surfaceContainerHighest
    }

    Rectangle {                               // active track
        anchors.verticalCenter: parent.verticalCenter
        width: knob.x + s.handle / 2
        height: 4
        radius: 2
        color: Theme.primary
    }

    Rectangle {                               // pressed halo
        visible: s.dragging
        width: 40
        height: 40
        radius: 20
        anchors.verticalCenter: knob.verticalCenter
        anchors.horizontalCenter: knob.horizontalCenter
        color: Theme.primary
        opacity: 0.12
    }

    Rectangle {
        id: knob
        anchors.verticalCenter: parent.verticalCenter
        width: s.handle
        height: s.handle
        radius: s.handle / 2
        color: Theme.primary
        x: s.frac * (s.width - s.handle)
    }

    Rectangle {                               // value bubble
        visible: s.dragging && s.valueText !== ""
        anchors.horizontalCenter: knob.horizontalCenter
        anchors.bottom: knob.top
        anchors.bottomMargin: 2
        width: bubbleText.implicitWidth + Theme.spacingM
        height: 24
        radius: 12
        color: Theme.surfaceContainerHighest
        border.width: 1
        border.color: Theme.primary

        StyledText {
            id: bubbleText
            anchors.centerIn: parent
            text: s.valueText
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.surfaceText
        }
    }

    MouseArea {
        anchors.fill: parent
        preventStealing: true
        cursorShape: Qt.PointingHandCursor

        function update(px) {
            const f = Math.max(0, Math.min(1, (px - s.handle / 2) / (s.width - s.handle)))
            let v = s.from + f * (s.to - s.from)
            if (s.step > 0) v = Math.round(v / s.step) * s.step
            s.dragValue = Math.max(s.from, Math.min(s.to, v))
        }

        onPressed: mouse => {
            s.dragging = true
            update(mouse.x)
        }
        onPositionChanged: mouse => {
            if (pressed) update(mouse.x)
        }
        onReleased: {
            s.dragging = false
            s.holding = true
            holdTimer.restart()
            s.released(s.dragValue)
        }
    }
}
