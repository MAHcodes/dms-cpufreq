import QtQuick
import qs.Common
import qs.DCommon.Widgets as DCommon

// The plugin's tab strip, now a thin adapter over DMS's DTabBar —
// true Material You 3 tabs. Keeps the plugin API:
// model [{ key, label, icon }], current (key), selected(key).
Item {
    id: tabs

    property var model: []              // [{ key, label, icon }]
    property string current: ""
    signal selected(string key)

    height: bar.height

    DCommon.DTabBar {
        id: bar
        width: parent.width

        model: tabs.model.map(m => ({ text: m.label, icon: m.icon }))
        currentIndex: {
            for (let i = 0; i < tabs.model.length; i++)
                if (tabs.model[i].key === tabs.current)
                    return i
            return -1
        }
        onTabClicked: index => tabs.selected(tabs.model[index].key)
    }
}
