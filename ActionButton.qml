import QtQuick
import qs.DCommon.Widgets as DCommon

// The plugin's action button, now a thin adapter over DMS's DButton —
// true Material You 3 (state layer, ripple, shape morph) with the plugin's
// API: text / icon / variant ("filled" | "tonal" | "outlined") / danger.
// `clicked` comes from the button itself and is not redeclared.
DCommon.DButton {
    id: btn

    property string icon: ""

    iconName: btn.icon
}
