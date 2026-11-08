import QtQuick
import qs.Common
import qs.Modules.Plugins
import qs.Widgets

PluginSettings {
    id: root

    pluginId: "cpuFreq"

    property string tab: "general"

    readonly property var columnOptions: [
        { label: "1", value: "1" },
        { label: "2", value: "2" },
        { label: "3", value: "3" },
        { label: "4", value: "4" },
        { label: "5", value: "5" },
        { label: "6", value: "6" }
    ]

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
            { key: "disk", label: "Disk", icon: "storage" },
            { key: "bat", label: "Battery", icon: "battery_full" }
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

    SelectionSetting {
        visible: root.tab === "general"
        settingKey: "barSeparator"
        label: "Separator between bar entries"
        description: "Dot or line between entries, in horizontal and vertical bars"
        options: [
            { label: "None", value: "none" },
            { label: "Dot", value: "dot" },
            { label: "Line", value: "line" }
        ]
        defaultValue: "none"
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
        label: "Summary value"
        description: "Average, minimum or maximum: the popout hero, and the bar until you change the toggles below"
        options: [
            { label: "Average", value: "avg" },
            { label: "Minimum", value: "min" },
            { label: "Maximum", value: "max" }
        ]
        defaultValue: "avg"
    }

    ToggleSetting {
        visible: root.tab === "freq"
        settingKey: "freqBarShowMin"
        label: "Bar: minimum"
        description: "Several can be on at once; each value becomes its own bar item with its own icon"
        defaultValue: false
    }

    ToggleSetting {
        visible: root.tab === "freq"
        settingKey: "freqBarShowAvg"
        label: "Bar: average"
        defaultValue: true
    }

    ToggleSetting {
        visible: root.tab === "freq"
        settingKey: "freqBarShowMax"
        label: "Bar: maximum"
        defaultValue: false
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

    SelectionSetting {
        visible: root.tab === "freq"
        settingKey: "freqColumns"
        label: "Per-core grid columns"
        description: "How many core frequencies share a row"
        options: root.columnOptions
        defaultValue: "2"
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
        visible: root.tab === "temp"
        settingKey: "tempCores"
        label: "Show per-core temperatures"
        description: "One sensor per physical core; hidden automatically if the CPU reports only a package sensor"
        defaultValue: true
    }

    SelectionSetting {
        visible: root.tab === "temp"
        settingKey: "tempColumns"
        label: "Per-core grid columns"
        description: "How many core readings share a row"
        options: root.columnOptions
        defaultValue: "3"
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

    SelectionSetting {
        visible: root.tab === "usage"
        settingKey: "usageColumns"
        label: "Per-core grid columns"
        description: "How many core usage readings share a row"
        options: root.columnOptions
        defaultValue: "2"
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

    ToggleSetting {
        visible: root.tab === "mem"
        settingKey: "memBarShowPercent"
        label: "Bar: percent used"
        description: "Several can be on at once; each value becomes its own bar item with its own icon"
        defaultValue: true
    }

    ToggleSetting {
        visible: root.tab === "mem"
        settingKey: "memBarShowUsed"
        label: "Bar: used"
        defaultValue: false
    }

    ToggleSetting {
        visible: root.tab === "mem"
        settingKey: "memBarShowAvailable"
        label: "Bar: available"
        defaultValue: false
    }

    ToggleSetting {
        visible: root.tab === "mem"
        settingKey: "memBarShowFree"
        label: "Bar: free"
        defaultValue: false
    }

    ToggleSetting {
        visible: root.tab === "mem"
        settingKey: "memBarShowUsed_total"
        label: "Bar: used / total"
        defaultValue: false
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

    ToggleSetting {
        visible: root.tab === "gpu"
        settingKey: "gpuBarShowUsage"
        label: "Bar: usage"
        description: "Several can be on at once; each value becomes its own bar item with its own icon"
        defaultValue: true
    }

    ToggleSetting {
        visible: root.tab === "gpu"
        settingKey: "gpuBarShowTemp"
        label: "Bar: temperature"
        defaultValue: false
    }

    ToggleSetting {
        visible: root.tab === "gpu"
        settingKey: "gpuBarShowVram"
        label: "Bar: VRAM used"
        defaultValue: false
    }

    ToggleSetting {
        visible: root.tab === "gpu"
        settingKey: "gpuBarShowPower"
        label: "Bar: power draw"
        defaultValue: false
    }

    ToggleSetting {
        visible: root.tab === "gpu"
        settingKey: "gpuBarShowClock"
        label: "Bar: graphics clock"
        defaultValue: false
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

    StyledText {
        visible: root.tab === "gpu"
        width: parent.width
        text: "Popout sections"
        font.pixelSize: Theme.fontSizeSmall
        font.weight: Font.Bold
        color: Theme.surfaceVariantText
    }

    ToggleSetting {
        visible: root.tab === "gpu"
        settingKey: "gpuShowUtil"
        label: "Utilization"
        description: "GPU, memory controller, encoder and decoder load"
        defaultValue: true
    }

    ToggleSetting {
        visible: root.tab === "gpu"
        settingKey: "gpuShowMem"
        label: "Memory"
        description: "VRAM used, free and reserved"
        defaultValue: true
    }

    ToggleSetting {
        visible: root.tab === "gpu"
        settingKey: "gpuShowThermals"
        label: "Thermals"
        description: "GPU and memory temperature, fan and clock limiters"
        defaultValue: true
    }

    ToggleSetting {
        visible: root.tab === "gpu"
        settingKey: "gpuShowPower"
        label: "Power"
        description: "Power draw and configured limits"
        defaultValue: true
    }

    ToggleSetting {
        visible: root.tab === "gpu"
        settingKey: "gpuShowClocks"
        label: "Clocks"
        description: "Graphics, memory, SM and video clocks, current and maximum"
        defaultValue: true
    }

    ToggleSetting {
        visible: root.tab === "gpu"
        settingKey: "gpuShowBus"
        label: "Bus & driver"
        description: "PCIe link, VBIOS, persistence/display/compute mode, UUID and serial"
        defaultValue: true
    }

    ToggleSetting {
        visible: root.tab === "gpu"
        settingKey: "gpuShowProcs"
        label: "Processes"
        description: "Compute processes currently using the GPU"
        defaultValue: true
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

    ToggleSetting {
        visible: root.tab === "disk"
        settingKey: "diskBarShowPercent"
        label: "Bar: percent used"
        description: "Several can be on at once; each value becomes its own bar item with its own icon"
        defaultValue: true
    }

    ToggleSetting {
        visible: root.tab === "disk"
        settingKey: "diskBarShowUsed"
        label: "Bar: used"
        defaultValue: false
    }

    ToggleSetting {
        visible: root.tab === "disk"
        settingKey: "diskBarShowFree"
        label: "Bar: free"
        defaultValue: false
    }

    ToggleSetting {
        visible: root.tab === "disk"
        settingKey: "diskBarShowUsed_total"
        label: "Bar: used / total"
        defaultValue: false
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

    ToggleSetting {
        visible: root.tab === "bat"
        settingKey: "batBar"
        label: "Show in bar"
        defaultValue: false
    }

    ToggleSetting {
        visible: root.tab === "bat"
        settingKey: "batTab"
        label: "Show tab in popout"
        defaultValue: true
    }

    ToggleSetting {
        visible: root.tab === "bat"
        settingKey: "batIcon"
        label: "Show icon in bar"
        description: "The icon follows the charge level and shows a bolt while charging"
        defaultValue: true
    }

    ToggleSetting {
        visible: root.tab === "bat"
        settingKey: "batShowUnit"
        label: "Show unit in bar"
        defaultValue: true
    }

    ToggleSetting {
        visible: root.tab === "bat"
        settingKey: "batBarShowPercent"
        label: "Bar: charge"
        description: "Several can be on at once; each value becomes its own bar item with its own icon. Several batteries are combined into one reading"
        defaultValue: true
    }

    ToggleSetting {
        visible: root.tab === "bat"
        settingKey: "batBarShowTime"
        label: "Bar: time remaining"
        defaultValue: false
    }

    ToggleSetting {
        visible: root.tab === "bat"
        settingKey: "batBarShowPower"
        label: "Bar: power draw"
        defaultValue: false
    }

    ToggleSetting {
        visible: root.tab === "bat"
        settingKey: "batBarShowEnergy"
        label: "Bar: energy"
        defaultValue: false
    }

    ToggleSetting {
        visible: root.tab === "bat"
        settingKey: "batPersist"
        label: "Keep charge limits across reboots"
        description: "Writes limits to /etc/tlp.d/99-dms-cpufreq.conf. When off, TLP only applies them until the next boot. Needs TLP; without it limits are always temporary"
        defaultValue: true
    }

    StyledText {
        visible: root.tab === "bat"
        width: parent.width
        text: "Popout pages"
        font.pixelSize: Theme.fontSizeSmall
        font.weight: Font.Bold
        color: Theme.surfaceVariantText
    }

    ToggleSetting {
        visible: root.tab === "bat"
        settingKey: "batShowHealth"
        label: "Battery health"
        description: "Overview page: capacity, health, cycles, power, voltage, temperature and model"
        defaultValue: true
    }

    ToggleSetting {
        visible: root.tab === "bat"
        settingKey: "batShowCharging"
        label: "Charging"
        description: "Charge limit presets and sliders, charge now, charge behaviour and maintenance"
        defaultValue: true
    }

    ToggleSetting {
        visible: root.tab === "bat"
        settingKey: "batShowTuning"
        label: "Tuning"
        description: "Edit TLP parameters per profile: governor, energy preference, turbo, Wi-Fi, PCIe, USB and more"
        defaultValue: true
    }

    StyledText {
        visible: root.tab === "bat"
        width: parent.width
        text: "Charge limits need hardware and kernel support (ThinkPad, ASUS, Dell, Framework and others). Tuning needs TLP. /etc/tlp.conf overrides the drop-in this plugin writes; the popout warns when it does."
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
    }
}
