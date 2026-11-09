import QtQuick
import qs.Common
import qs.DCommon.Widgets as DCommon

// The plugin's single-select control, now a thin adapter over DMS's
// DButtonGroup — the same Material You 3 segmented buttons the built-in
// battery widget's power profile section uses. Keeps the plugin-facing API
// (options / current / selected(value)) so existing call sites are unchanged.
DCommon.DButtonGroup {
    id: sc

    property var options: []            // strings, or { label, value, icon }
    property string current: ""
    property int maxPerRow: 5           // kept for API compatibility; DButtonGroup never wraps

    signal selected(string value)

    function optLabel(o) { return typeof o === "string" ? o : o.label }
    function optValue(o) { return typeof o === "string" ? o : o.value }
    function optIcon(o) { return typeof o === "string" ? "" : (o.icon || "") }

    fillWidth: true
    checkEnabled: false                 // selection reads from the fill color, like the battery widget
    size: options.length > 3 ? "small" : "medium"
    model: options.map(o => ({ text: optLabel(o), icon: optIcon(o) }))
    currentIndex: {
        for (let i = 0; i < options.length; i++)
            if (optValue(options[i]) === current)
                return i
        return -1
    }
    onSelectionChanged: (index, sel) => {
        if (sel) selected(optValue(options[index]))
    }
}
