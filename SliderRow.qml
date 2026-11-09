import QtQuick
import qs.Common
import qs.Widgets
import qs.DCommon.Widgets as DCommon

// Label + live value above DMS's Material You 3 slider (DSlider).
// Keeps the plugin API. `released` fires once per interaction (DSlider's
// sliderDragFinished: release, wheel or keys) — never per drag tick — so
// privileged applies stay single-shot.
Column {
    id: sr

    property string icon: ""
    property string label: ""
    property string valueText: ""
    property real from: 0
    property real to: 1
    property real value: 0
    property real step: 1
    readonly property real shown: slider.value
    signal released(real newValue)

    spacing: Theme.spacingXS

    Item {
        width: sr.width
        height: 24

        Row {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.spacingS

            DankIcon {
                visible: sr.icon !== ""
                name: sr.icon
                size: Theme.iconSize - 8
                color: Theme.surfaceVariantText
                anchors.verticalCenter: parent.verticalCenter
            }
            StyledText {
                text: sr.label
                font.pixelSize: Theme.fontSizeMedium
                color: Theme.surfaceText
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        StyledText {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: sr.valueText
            font.pixelSize: Theme.fontSizeMedium
            color: Theme.surfaceVariantText
        }
    }

    DCommon.DSlider {
        id: slider
        width: sr.width
        minimum: Math.round(sr.from)
        maximum: Math.round(sr.to)
        step: Math.max(1, Math.round(sr.step))
        showValue: false                 // the header row already shows the value
        value: Math.round(sr.value)

        onSliderDragFinished: finalValue => {
            sr.released(finalValue)
            holdTimer.restart()
        }
    }

    // DSlider breaks its value binding while dragging, so external (poll)
    // updates are pushed manually. The timer snaps back if an apply fails and
    // the poll never confirms the dragged value.
    Timer {
        id: holdTimer
        interval: 4000
        onTriggered: if (slider.value !== Math.round(sr.value)) slider.value = Math.round(sr.value)
    }

    onValueChanged: {
        if (!slider.isDragging) {
            slider.value = Math.round(value)
            if (slider.value === Math.round(value))
                holdTimer.stop()
        }
    }
}
