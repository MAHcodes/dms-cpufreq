import QtQuick
import qs.Common
import qs.Widgets

// One editable TLP parameter: segmented choice, switch or slider, plus a hint when
// the value is overridden by /etc/tlp.conf and a reset link when this plugin manages it.
Column {
    id: f

    property string icon: ""
    property string label: ""
    property string type: "seg"             // "seg" | "switch" | "slider"
    property var options: []                // seg: strings or { label, value, icon }
    property string value: ""               // effective value as TLP sees it ("" = unset)
    property string yesValue: "1"           // switch: value written when turned on / off
    property string noValue: "0"
    property real from: 0                   // slider
    property real to: 100
    property string unit: ""
    property bool managed: false            // present in this plugin's /etc/tlp.d drop-in
    property string source: ""              // file the effective value comes from
    signal commit(string newValue)
    signal reset()

    // keep what the user just chose on screen until TLP reports it back
    property string pending: ""
    readonly property string shown: pending !== "" ? pending : value
    readonly property bool overridden: managed && source !== "" && source.indexOf("99-dms-cpufreq") < 0

    onValueChanged: pending = ""

    spacing: Theme.spacingXS
    visible: type !== "seg" || options.length > 0

    Timer {
        id: pendingTimer
        interval: 8000
        onTriggered: f.pending = ""
    }

    function choose(v) {
        pending = v
        pendingTimer.restart()
        commit(v)
    }

    Column {
        visible: f.type === "seg"
        width: parent.width
        spacing: Theme.spacingXS

        FieldLabel { text: f.label; icon: f.icon }
        SegmentedControl {
            width: parent.width
            options: f.options
            current: f.shown
            onSelected: v => f.choose(v)
        }
    }

    SwitchRow {
        visible: f.type === "switch"
        width: parent.width
        icon: f.icon
        label: f.label
        checked: f.shown !== "" && f.shown !== f.noValue
        onToggled: v => f.choose(v ? f.yesValue : f.noValue)
    }

    SliderRow {
        id: sl
        visible: f.type === "slider"
        width: parent.width
        icon: f.icon
        label: f.label
        from: f.from
        to: f.to
        step: 1
        value: parseInt(f.shown) || 0
        valueText: Math.round(sl.shown) + f.unit
        onReleased: nv => f.choose(String(Math.round(nv)))
    }

    StyledText {
        visible: f.overridden
        width: parent.width
        text: "Overridden by " + f.source.replace(/\s.*$/, "") + ", which is read last. Comment it out there for this setting to take effect."
        wrapMode: Text.WordWrap
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.warning !== undefined ? Theme.warning : Theme.surfaceVariantText
    }

    Item {
        visible: f.managed
        width: parent.width
        height: 28

        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.spacingXS
            opacity: resetMouse.containsMouse ? 1 : 0.8

            DankIcon {
                name: "restart_alt"
                size: Theme.iconSize - 10
                color: Theme.primary
                anchors.verticalCenter: parent.verticalCenter
            }
            StyledText {
                text: "Reset to TLP default"
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.primary
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        MouseArea {
            id: resetMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: f.reset()
        }
    }
}
