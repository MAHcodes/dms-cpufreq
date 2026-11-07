import QtQuick
import qs.Common
import qs.Modules.Plugins
import qs.Widgets

PluginSettings {
    id: root

    pluginId: "cpuFreq"

    property string tab: "general"

    StyledText {
        width: parent.width
        text: "System Monitor"
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    StyledText {
        width: parent.width
        text: "Pick what shows in the bar and in the popout. Entries in the bar are separated by two spaces. Metrics your hardware does not report are hidden automatically."
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
    }

    M3Tabs {
        width: parent.width
        current: root.tab
        model: [
            { key: "general", label: "General", icon: "tune" },
            { key: "freq", label: "Freq", icon: "speed" },
            { key: "temp", label: "Temp", icon: "thermostat" },
            { key: "usage", label: "Usage", icon: "memory" },
            { key: "mem", label: "RAM", icon: "developer_board" },
            { key: "gpu", label: "GPU", icon: "auto_awesome_mosaic" },
            { key: "fans", label: "Fans", icon: "mode_fan" },
            { key: "disk", label: "Disk", icon: "storage" }
        ]
        onSelected: key => root.tab = key
    }

    SelectionSetting {
        visible: root.tab === "general"
        settingKey: "refreshInterval"
        label: "Refresh interval"
        options: [
            { label: "1 second", value: "1000" },
            { label: "2 seconds", value: "2000" },
            { label: "5 seconds", value: "5000" }
        ]
        defaultValue: "2000"
    }

    SelectionSetting {
        visible: root.tab === "general"
        settingKey: "coreColumns"
        label: "Per-core grid columns"
        options: [
            { label: "1", value: "1" },
            { label: "2", value: "2" },
            { label: "3", value: "3" },
            { label: "4", value: "4" }
        ]
        defaultValue: "2"
    }

    ToggleSetting {
        visible: root.tab === "general"
        settingKey: "restoreOnLaunch"
        label: "Restore last CPU settings on launch"
        defaultValue: false
    }

    StyledText {
        visible: root.tab === "general"
        width: parent.width
        text: "Governor, EPP, turbo and frequency limits reset on every reboot. Restoring re-applies your last choices a few seconds after the shell starts."
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
    }

    ToggleSetting {
        visible: root.tab === "freq"
        settingKey: "freqBar"
        label: "Show in bar"
        defaultValue: true
    }

    ToggleSetting {
        visible: root.tab === "freq"
        settingKey: "freqTab"
        label: "Show tab in popout"
        defaultValue: true
    }

    ToggleSetting {
        visible: root.tab === "freq"
        settingKey: "freqIcon"
        label: "Show icon in bar"
        defaultValue: true
    }

    ToggleSetting {
        visible: root.tab === "freq"
        settingKey: "freqShowUnit"
        label: "Show unit in bar"
        defaultValue: true
    }

    SelectionSetting {
        visible: root.tab === "freq"
        settingKey: "freqMode"
        label: "Value shown in bar"
        options: [
            { label: "Average", value: "avg" },
            { label: "Minimum", value: "min" },
            { label: "Maximum", value: "max" }
        ]
        defaultValue: "avg"
    }

    SelectionSetting {
        visible: root.tab === "freq"
        settingKey: "freqScale"
        label: "Unit"
        options: [
            { label: "GHz", value: "GHz" },
            { label: "MHz", value: "MHz" }
        ]
        defaultValue: "GHz"
    }

    SelectionSetting {
        visible: root.tab === "freq"
        settingKey: "freqPrecision"
        label: "Decimal places (GHz)"
        options: [
            { label: "0", value: "0" },
            { label: "1", value: "1" },
            { label: "2", value: "2" }
        ]
        defaultValue: "1"
    }

    ToggleSetting {
        visible: root.tab === "freq"
        settingKey: "freqShowMin"
        label: "Show minimum frequency limit"
        defaultValue: true
    }

    ToggleSetting {
        visible: root.tab === "freq"
        settingKey: "freqShowMax"
        label: "Show maximum frequency limit"
        defaultValue: true
    }

    ToggleSetting {
        visible: root.tab === "freq"
        settingKey: "freqCores"
        label: "Show per-core frequencies"
        defaultValue: true
    }

    ToggleSetting {
        visible: root.tab === "temp"
        settingKey: "tempBar"
        label: "Show in bar"
        defaultValue: false
    }

    ToggleSetting {
        visible: root.tab === "temp"
        settingKey: "tempTab"
        label: "Show tab in popout"
        defaultValue: true
    }

    ToggleSetting {
        visible: root.tab === "temp"
        settingKey: "tempIcon"
        label: "Show icon in bar"
        defaultValue: true
    }

    ToggleSetting {
        visible: root.tab === "temp"
        settingKey: "tempShowUnit"
        label: "Show unit in bar"
        defaultValue: true
    }

    SelectionSetting {
        visible: root.tab === "temp"
        settingKey: "tempScale"
        label: "Unit"
        options: [
            { label: "Celsius", value: "C" },
            { label: "Fahrenheit", value: "F" }
        ]
        defaultValue: "C"
    }

    ToggleSetting {
        visible: root.tab === "usage"
        settingKey: "usageBar"
        label: "Show in bar"
        defaultValue: false
    }

    ToggleSetting {
        visible: root.tab === "usage"
        settingKey: "usageTab"
        label: "Show tab in popout"
        defaultValue: true
    }

    ToggleSetting {
        visible: root.tab === "usage"
        settingKey: "usageIcon"
        label: "Show icon in bar"
        defaultValue: true
    }

    ToggleSetting {
        visible: root.tab === "usage"
        settingKey: "usageShowUnit"
        label: "Show unit in bar"
        defaultValue: true
    }

    ToggleSetting {
        visible: root.tab === "mem"
        settingKey: "memBar"
        label: "Show in bar"
        defaultValue: false
    }

    ToggleSetting {
        visible: root.tab === "mem"
        settingKey: "memTab"
        label: "Show tab in popout"
        defaultValue: true
    }

    ToggleSetting {
        visible: root.tab === "mem"
        settingKey: "memIcon"
        label: "Show icon in bar"
        defaultValue: true
    }

    ToggleSetting {
        visible: root.tab === "mem"
        settingKey: "memShowUnit"
        label: "Show unit in bar"
        defaultValue: true
    }

    SelectionSetting {
        visible: root.tab === "mem"
        settingKey: "memDisplay"
        label: "Value shown in bar"
        options: [
            { label: "Percent used", value: "percent" },
            { label: "Used", value: "used" },
            { label: "Used / total", value: "used_total" }
        ]
        defaultValue: "percent"
    }

    SelectionSetting {
        visible: root.tab === "mem"
        settingKey: "memScale"
        label: "Unit"
        options: [
            { label: "Automatic", value: "auto" },
            { label: "GiB", value: "GiB" },
            { label: "MiB", value: "MiB" }
        ]
        defaultValue: "auto"
    }

    ToggleSetting {
        visible: root.tab === "gpu"
        settingKey: "gpuBar"
        label: "Show in bar"
        defaultValue: false
    }

    ToggleSetting {
        visible: root.tab === "gpu"
        settingKey: "gpuTab"
        label: "Show tab in popout"
        defaultValue: true
    }

    ToggleSetting {
        visible: root.tab === "gpu"
        settingKey: "gpuIcon"
        label: "Show icon in bar"
        defaultValue: true
    }

    ToggleSetting {
        visible: root.tab === "gpu"
        settingKey: "gpuShowUnit"
        label: "Show unit in bar"
        defaultValue: true
    }

    SelectionSetting {
        visible: root.tab === "gpu"
        settingKey: "gpuDisplay"
        label: "Value shown in bar"
        options: [
            { label: "Usage", value: "usage" },
            { label: "Temperature", value: "temp" },
            { label: "VRAM used", value: "vram" }
        ]
        defaultValue: "usage"
    }

    SelectionSetting {
        visible: root.tab === "gpu"
        settingKey: "gpuIndex"
        label: "GPU shown in bar"
        options: [
            { label: "First", value: "0" },
            { label: "Second", value: "1" },
            { label: "Third", value: "2" },
            { label: "Fourth", value: "3" }
        ]
        defaultValue: "0"
    }

    ToggleSetting {
        visible: root.tab === "fans"
        settingKey: "fansBar"
        label: "Show in bar"
        defaultValue: false
    }

    ToggleSetting {
        visible: root.tab === "fans"
        settingKey: "fansTab"
        label: "Show tab in popout"
        defaultValue: true
    }

    ToggleSetting {
        visible: root.tab === "fans"
        settingKey: "fansIcon"
        label: "Show icon in bar"
        defaultValue: true
    }

    ToggleSetting {
        visible: root.tab === "fans"
        settingKey: "fansShowUnit"
        label: "Show unit in bar"
        defaultValue: true
    }

    SelectionSetting {
        visible: root.tab === "fans"
        settingKey: "fansDisplay"
        label: "Value shown in bar"
        options: [
            { label: "Fastest fan", value: "max" },
            { label: "Average", value: "avg" }
        ]
        defaultValue: "max"
    }

    ToggleSetting {
        visible: root.tab === "disk"
        settingKey: "diskBar"
        label: "Show in bar"
        defaultValue: false
    }

    ToggleSetting {
        visible: root.tab === "disk"
        settingKey: "diskTab"
        label: "Show tab in popout"
        defaultValue: true
    }

    ToggleSetting {
        visible: root.tab === "disk"
        settingKey: "diskIcon"
        label: "Show icon in bar"
        defaultValue: true
    }

    ToggleSetting {
        visible: root.tab === "disk"
        settingKey: "diskShowUnit"
        label: "Show unit in bar"
        defaultValue: true
    }

    SelectionSetting {
        visible: root.tab === "disk"
        settingKey: "diskDisplay"
        label: "Value shown in bar"
        options: [
            { label: "Percent used", value: "percent" },
            { label: "Used", value: "used" },
            { label: "Free", value: "free" },
            { label: "Used / total", value: "used_total" }
        ]
        defaultValue: "percent"
    }

    SelectionSetting {
        visible: root.tab === "disk"
        settingKey: "diskScale"
        label: "Unit"
        options: [
            { label: "Automatic", value: "auto" },
            { label: "GiB", value: "GiB" },
            { label: "GB", value: "GB" }
        ]
        defaultValue: "auto"
    }

    StringSetting {
        visible: root.tab === "disk"
        settingKey: "diskMount"
        label: "Mount point shown in bar"
        description: "Falls back to the first filesystem if this one is not mounted"
        placeholder: "/"
        defaultValue: "/"
    }
}
