import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins

PluginComponent {
    id: root

    layerNamespacePlugin: "cpufreq"

    property var popoutService: null

    // Installed by install.sh (root-owned, referenced by the polkit policy).
    readonly property string ctl: "/usr/local/bin/dms-cpufreqctl"

    // ===================================================== metric registry ==
    readonly property var metricKeys: ["freq", "temp", "usage", "mem", "gpu", "fans", "disk"]
    readonly property var metricIcons: ({
        freq: "speed",
        temp: "thermostat",
        usage: "memory",
        mem: "developer_board",
        gpu: "auto_awesome_mosaic",
        fans: "mode_fan",
        disk: "storage"
    })
    readonly property var metricLabels: ({
        freq: "Freq", temp: "Temp", usage: "Usage", mem: "RAM", gpu: "GPU", fans: "Fans", disk: "Disk"
    })
    readonly property var governorIcons: ({
        performance: "rocket_launch", powersave: "eco", schedutil: "balance",
        ondemand: "trending_up", conservative: "trending_down", userspace: "person"
    })
    readonly property var eppIcons: ({
        performance: "rocket_launch", balance_performance: "speed",
        "default": "restart_alt", balance_power: "balance", power: "eco"
    })
    readonly property var eppShort: ({
        "default": "Default", performance: "Perf", balance_performance: "Bal. perf",
        balance_power: "Bal. power", power: "Power"
    })
    readonly property var profileOptions: [
        { label: "Power saver", value: "saver", icon: "eco" },
        { label: "Balanced", value: "balanced", icon: "balance" },
        { label: "Performance", value: "performance", icon: "rocket_launch" }
    ]

    // ======================================================== settings =====
    function opt(key, def) {
        const v = pluginData ? pluginData[key] : undefined
        return (v === undefined || v === null || v === "") ? def : v
    }

    property int coreColumns: parseInt(opt("coreColumns", "2"))

    // ========================================================== state ======
    property var snap: null                      // last parsed status
    property string err: "Waiting for data. If this stays empty, the helper is not installed: run install.sh from this plugin's folder (see README)."
    property var prevStat: null
    property real usageAll: 0
    property var usageById: ({})
    property var pendingApply: []
    property var currentArgs: []

    // lists that feed Repeaters/segmented controls are only reassigned when
    // their content changes, so delegates are not rebuilt on every poll
    property var _sig: ({})
    property var governorOptions: []
    property var eppOptions: []
    property var tabs: []

    readonly property var cpu: snap && snap.cpu ? snap.cpu : null
    readonly property var cores: cpu ? cpu.cores : []
    readonly property var mem: snap && snap.mem ? snap.mem : null
    readonly property var gpus: snap && snap.gpus ? snap.gpus : []
    readonly property var fans: snap && snap.fans ? snap.fans : []
    readonly property var disks: snap && snap.disks ? snap.disks : []

    function assignStable(prop, val) {
        const s = JSON.stringify(val)
        if (_sig[prop] === s) return
        _sig[prop] = s
        root[prop] = val
    }

    // ===================================================== availability ====
    function available(key) {
        switch (key) {
        case "freq": return cpu !== null && cpu.hasFreq === true && cores.length > 0
        case "temp": return cpu !== null && (cpu.temp.pkg !== null || cpu.temp.cores.length > 0)
        case "usage": return cpu !== null
        case "mem": return mem !== null
        case "gpu": return gpus.length > 0
        case "fans": return fans.length > 0
        case "disk": return disks.length > 0
        }
        return false
    }

    function barShown(key) { return available(key) && opt(key + "Bar", key === "freq") }
    function tabShown(key) { return available(key) && opt(key + "Tab", true) }
    function barIconShown(key) { return opt(key + "Icon", true) }

    function firstBarKey() {
        for (const k of metricKeys) if (barShown(k)) return k
        return ""
    }

    // which helper sections are worth collecting (nvidia-smi etc. only when needed)
    function sections() {
        const need = k => opt(k + "Bar", k === "freq") || opt(k + "Tab", true)
        const s = []
        if (need("freq") || need("temp") || need("usage")) s.push("cpu")
        if (need("mem")) s.push("mem")
        if (need("gpu")) s.push("gpu")
        if (need("fans")) s.push("fans")
        if (need("disk")) s.push("disk")
        return s.length ? s : ["cpu"]
    }

    function refreshTabs() {
        const m = []
        for (const k of metricKeys) {
            if (tabShown(k)) m.push({ key: k, label: metricLabels[k], icon: metricIcons[k] })
        }
        assignStable("tabs", m)
    }

    onPluginDataChanged: refreshTabs()

    // ========================================================= formatting ==
    function cap(s) { return s.length ? s.charAt(0).toUpperCase() + s.slice(1) : s }

    function fmtFreq(khz, bare) {
        if (khz === null || khz === undefined) return "–"
        if (opt("freqScale", "GHz") === "MHz") return Math.round(khz / 1000) + (bare ? "" : " MHz")
        return (khz / 1e6).toFixed(parseInt(opt("freqPrecision", "1"))) + (bare ? "" : " GHz")
    }

    function fmtTemp(mc, bare) {
        if (mc === null || mc === undefined) return "–"
        const c = mc / 1000
        if (opt("tempScale", "C") === "F") return Math.round(c * 9 / 5 + 32) + (bare ? "°" : "°F")
        return Math.round(c) + (bare ? "°" : "°C")
    }

    function pickUnit(b, scale) {
        if (scale !== "auto") return scale
        return b >= 1099511627776 ? "TiB" : (b >= 1073741824 ? "GiB" : "MiB")
    }
    function unitDiv(u) {
        return ({ TiB: 1099511627776, GiB: 1073741824, MiB: 1048576, GB: 1e9, MB: 1e6 })[u]
    }
    function fmtNum(v) { return v >= 100 ? v.toFixed(0) : v.toFixed(1) }
    function fmtBytes(b, scale, withUnit) {
        const u = pickUnit(b, scale)
        return fmtNum(b / unitDiv(u)) + (withUnit ? " " + u : "")
    }
    function fmtBytesPair(a, b, scale, withUnit) {
        const u = pickUnit(b, scale)
        return fmtNum(a / unitDiv(u)) + "/" + fmtNum(b / unitDiv(u)) + (withUnit ? " " + u : "")
    }

    function clamp100(v) { return Math.max(0, Math.min(100, v)) }

    // ============================================================ metrics ==
    function freqList() {
        return cores.map(c => c.cur).filter(v => v !== null && v !== undefined)
    }
    function panelFreq() {
        const f = freqList()
        if (!f.length) return null
        const mode = opt("freqMode", "avg")
        if (mode === "min") return Math.min.apply(null, f)
        if (mode === "max") return Math.max.apply(null, f)
        return f.reduce((a, b) => a + b, 0) / f.length
    }
    function modeLabel() {
        const m = opt("freqMode", "avg")
        return m === "min" ? "Minimum" : (m === "max" ? "Maximum" : "Average")
    }
    function freqFraction(khz) {
        if (!cpu || khz === null || khz === undefined || cpu.hwMax <= cpu.hwMin) return -1
        return clamp100(100 * (khz - cpu.hwMin) / (cpu.hwMax - cpu.hwMin))
    }

    function pkgTemp() {
        if (!cpu || !cpu.temp) return null
        if (cpu.temp.pkg !== null) return cpu.temp.pkg
        if (cpu.temp.cores.length) return Math.max.apply(null, cpu.temp.cores.map(t => t.mc))
        return null
    }
    function tempCoreList() { return cpu && cpu.temp ? cpu.temp.cores : [] }

    function memUsedB() { return mem ? (mem.total - mem.avail) * 1024 : 0 }
    function memTotalB() { return mem ? mem.total * 1024 : 0 }
    function memPct() { return mem && mem.total > 0 ? 100 * (mem.total - mem.avail) / mem.total : 0 }

    function gpuSel() {
        if (!gpus.length) return null
        const i = parseInt(opt("gpuIndex", "0"))
        return gpus[Math.min(isNaN(i) ? 0 : i, gpus.length - 1)]
    }
    function gpuVramPct(g) { return g && g.vramTotal > 0 ? 100 * g.vramUsed / g.vramTotal : 0 }
    function gpuAsleep(g) { return g.state === "suspended" || g.state === "suspending" }

    function fanRpm() {
        if (!fans.length) return null
        const r = fans.map(f => f.rpm)
        if (opt("fansDisplay", "max") === "avg") return r.reduce((a, b) => a + b, 0) / r.length
        return Math.max.apply(null, r)
    }

    function diskSel() {
        if (!disks.length) return null
        const m = opt("diskMount", "/")
        for (const d of disks) if (d.mount === m) return d
        return disks[0]
    }
    function diskPct(d) { return d && (d.used + d.avail) > 0 ? 100 * d.used / (d.used + d.avail) : 0 }

    // text for one bar entry; `bare` forces no unit (vertical bar)
    function barText(key, bare) {
        const u = bare ? false : opt(key + "ShowUnit", true)
        if (key === "freq") return fmtFreq(panelFreq(), !u)
        if (key === "temp") return fmtTemp(pkgTemp(), !u)
        if (key === "usage") return Math.round(usageAll) + (u ? "%" : "")
        if (key === "mem") {
            const d = opt("memDisplay", "percent")
            const sc = opt("memScale", "auto")
            if (d === "percent") return Math.round(memPct()) + (u ? "%" : "")
            if (d === "used") return fmtBytes(memUsedB(), sc, u)
            return fmtBytesPair(memUsedB(), memTotalB(), sc, u)
        }
        if (key === "gpu") {
            const g = gpuSel()
            if (!g) return "–"
            const d = opt("gpuDisplay", "usage")
            if (d === "temp") return g.temp === null ? "–" : fmtTemp(g.temp, !u)
            if (d === "vram") return g.vramTotal > 0 ? Math.round(gpuVramPct(g)) + (u ? "%" : "") : "–"
            return g.usage === null ? "–" : g.usage + (u ? "%" : "")
        }
        if (key === "fans") {
            const r = fanRpm()
            return r === null ? "–" : Math.round(r) + (u ? " RPM" : "")
        }
        if (key === "disk") {
            const d = diskSel()
            if (!d) return "–"
            const disp = opt("diskDisplay", "percent")
            const sc = opt("diskScale", "auto")
            if (disp === "percent") return Math.round(diskPct(d)) + (u ? "%" : "")
            if (disp === "used") return fmtBytes(d.used, sc, u)
            if (disp === "free") return fmtBytes(d.avail, sc, u)
            return fmtBytesPair(d.used, d.used + d.avail, sc, u)
        }
        return ""
    }

    function pct(a, b) {
        const dt = b[0] - a[0]
        const di = b[1] - a[1]
        return dt > 0 ? Math.max(0, Math.min(100, 100 * (dt - di) / dt)) : 0
    }

    // per-index getters so grid delegates survive polls
    function coreId(i) { return cores[i] ? cores[i].id : i }
    function coreFreq(i) { return cores[i] ? cores[i].cur : null }
    function coreUsage(i) { return cores[i] ? (usageById[cores[i].id] || 0) : 0 }

    function buildOptions(list, icons, shorts) {
        return list.map(v => ({
            value: v,
            label: (shorts && shorts[v]) ? shorts[v] : cap(v.replace(/_/g, " ")),
            icon: icons[v] || ""
        }))
    }

    // ========================================================== polling ====
    function handleStatus(text) {
        let j
        try {
            j = JSON.parse(text)
        } catch (e) {
            snap = null
            err = "Could not parse output of dms-cpufreqctl status"
            return
        }

        if (j.cpu) {
            const now = {}
            for (const c of j.cpu.stat.cores) now[c[0]] = [c[1], c[2]]
            if (prevStat) {
                usageAll = pct(prevStat.all, j.cpu.stat.all)
                const byId = {}
                for (const id in now) byId[id] = prevStat.cores[id] ? pct(prevStat.cores[id], now[id]) : 0
                usageById = byId
            }
            prevStat = { all: j.cpu.stat.all, cores: now }
            assignStable("governorOptions", buildOptions(j.cpu.governors, governorIcons, null))
            assignStable("eppOptions", buildOptions(j.cpu.epps, eppIcons, eppShort))
        }

        snap = j
        err = ""
        refreshTabs()
    }

    Process {
        id: statusProc
        command: [root.ctl, "status"].concat(root.sections())
        stdout: StdioCollector {
            onStreamFinished: root.handleStatus(this.text)
        }
        onExited: (code, status) => {
            if (code !== 0) {
                root.snap = null
                root.err = "dms-cpufreqctl status failed (exit " + code + "). Run install.sh from this plugin's folder (see README)."
            }
        }
    }

    Timer {
        interval: parseInt(root.opt("refreshInterval", "2000"))
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: if (!statusProc.running) statusProc.running = true
    }

    // ========================================================== apply ======
    Process {
        id: applyProc
        stderr: StdioCollector { id: applyErr }
        onExited: (code, status) => root.applyDone(code, applyErr.text)
    }

    function apply(args) {
        pendingApply.push(args)
        if (!applyProc.running) nextApply()
    }

    function nextApply() {
        if (!pendingApply.length) return
        currentArgs = pendingApply.shift()
        applyProc.command = ["pkexec", ctl, "apply"].concat(currentArgs)
        applyProc.running = true
    }

    function applyDone(code, errText) {
        if (code === 0) {
            remember(currentArgs)
        } else if (code === 126 || code === 127) {
            ToastService?.showInfo("System Monitor: authentication cancelled or failed")
        } else {
            const first = (errText || "").split("\n")[0]
            ToastService?.showInfo("System Monitor: " + (first || "change failed"))
        }
        if (!statusProc.running) statusProc.running = true
        nextApply()
    }

    // ================================================ persistence/restore ==
    function loadSaved() {
        try {
            const raw = pluginService ? pluginService.loadPluginState(pluginId, "saved", "{}") : "{}"
            return typeof raw === "string" ? JSON.parse(raw) : (raw || {})
        } catch (e) {
            return {}
        }
    }

    function remember(args) {
        const cur = loadSaved()
        for (const kv of args) {
            const i = kv.indexOf("=")
            cur[kv.slice(0, i)] = kv.slice(i + 1)
        }
        pluginService?.savePluginState(pluginId, "saved", JSON.stringify(cur))
    }

    Timer {
        id: restoreTimer
        interval: 4000
        running: root.opt("restoreOnLaunch", false)
        repeat: false
        onTriggered: {
            const saved = root.loadSaved()
            const args = []
            for (const k in saved) args.push(k + "=" + saved[k])
            if (args.length) root.apply(args)
        }
    }

    // ========================================================== actions ====
    function setGovernor(g) { apply(["governor=" + g]) }
    function setEpp(e) { apply(["epp=" + e]) }
    function setTurbo(on) { apply(["turbo=" + (on ? 1 : 0)]) }

    // min/max: if the request would cross the other bound, move both.
    function setMin(khz) {
        const v = Math.round(khz)
        if (cpu && v > cpu.scalingMax) apply(["min=" + v, "max=" + v])
        else apply(["min=" + v])
    }
    function setMax(khz) {
        const v = Math.round(khz)
        if (cpu && v < cpu.scalingMin) apply(["min=" + v, "max=" + v])
        else apply(["max=" + v])
    }

    function pick(list, candidates) {
        for (const c of candidates) if (list.indexOf(c) >= 0) return c
        return null
    }

    function presetArgs(name) {
        if (!cpu) return []
        const hasEpp = cpu.epps.length > 0
        let g, e, t
        if (name === "saver") {
            g = pick(cpu.governors, ["powersave"])
            e = pick(cpu.epps, ["power", "balance_power"])
            t = 0
        } else if (name === "balanced") {
            g = pick(cpu.governors, hasEpp ? ["powersave"] : ["schedutil", "ondemand", "powersave"])
            e = pick(cpu.epps, ["balance_performance", "default"])
            t = 1
        } else {
            g = pick(cpu.governors, ["performance"])
            e = pick(cpu.epps, ["performance"])
            t = 1
        }
        const args = []
        if (g) args.push("governor=" + g)
        if (e) args.push("epp=" + e)
        if (cpu.turboSupported) args.push("turbo=" + t)
        args.push("min=hw", "max=hw")
        return args
    }

    function applyPreset(name) {
        const args = presetArgs(name)
        if (args.length) apply(args)
    }

    // Which preset (if any) matches the live sysfs state; "" means custom.
    function activeProfile() {
        if (!cpu) return ""
        const names = ["saver", "balanced", "performance"]
        for (let n = 0; n < names.length; n++) {
            const args = presetArgs(names[n])
            let ok = true
            for (const kv of args) {
                const i = kv.indexOf("=")
                const k = kv.slice(0, i)
                const v = kv.slice(i + 1)
                if (k === "governor" && cpu.governor !== v) ok = false
                else if (k === "epp" && cpu.epp !== v) ok = false
                else if (k === "turbo" && cpu.turbo !== (v === "1")) ok = false
                else if (k === "min" && cpu.scalingMin > cpu.hwMin) ok = false
                else if (k === "max" && cpu.scalingMax < cpu.hwMax) ok = false
            }
            if (ok) return names[n]
        }
        return ""
    }

    // ===================================================== bar sizing ======
    // Same sizing the built-in DankBar widgets use: text follows the bar's thickness,
    // font scale and "maximize widget text" settings (injected by DMS into bar plugins).
    // Falls back to fixed sizes if this DMS version does not provide them.
    readonly property int barFontSize: (typeof Theme.barTextSize === "function" && root.barThickness)
        ? Theme.barTextSize(root.barThickness, root.barConfig?.fontScale, root.barConfig?.maximizeWidgetText)
        : Theme.fontSizeMedium
    readonly property int barIconSize: root.iconSize > 0 ? root.iconSize : Theme.iconSize - 6
    readonly property color barTextColor: Theme.widgetTextColor !== undefined ? Theme.widgetTextColor : Theme.surfaceText

    // ======================================================== bar pills ====
    // Entries are separated by two (non-breaking) spaces.
    horizontalBarPill: Component {
        Row {
            spacing: 0

            StyledText {
                visible: root.firstBarKey() === ""
                text: root.snap ? "–" : "…"
                font.pixelSize: root.barFontSize
                color: root.barTextColor
                anchors.verticalCenter: parent.verticalCenter
            }

            Repeater {
                model: root.metricKeys

                delegate: Row {
                    spacing: 0
                    visible: root.barShown(modelData)

                    StyledText {
                        visible: root.firstBarKey() !== modelData
                        text: "\u00A0\u00A0"
                        font.pixelSize: root.barFontSize
                        color: root.barTextColor
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Row {
                        spacing: Theme.spacingXS
                        anchors.verticalCenter: parent.verticalCenter

                        DankIcon {
                            visible: root.barIconShown(modelData)
                            name: root.metricIcons[modelData]
                            size: root.barIconSize
                            color: Theme.primary
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        StyledText {
                            text: root.barText(modelData, false)
                            font.pixelSize: root.barFontSize
                            color: root.barTextColor
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }
        }
    }

    verticalBarPill: Component {
        Column {
            spacing: Theme.spacingS

            StyledText {
                visible: root.firstBarKey() === ""
                text: root.snap ? "–" : "…"
                font.pixelSize: root.barFontSize
                color: root.barTextColor
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Repeater {
                model: root.metricKeys

                delegate: Column {
                    spacing: Theme.spacingXS
                    visible: root.barShown(modelData)
                    anchors.horizontalCenter: parent.horizontalCenter

                    DankIcon {
                        visible: root.barIconShown(modelData)
                        name: root.metricIcons[modelData]
                        size: root.barIconSize
                        color: Theme.primary
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    StyledText {
                        text: root.barText(modelData, true)
                        font.pixelSize: root.barFontSize
                        color: root.barTextColor
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
            }
        }
    }

    // ========================================================== popout =====
    popoutWidth: 480
    popoutHeight: 660

    popoutContent: Component {
        PopoutComponent {
            id: pop

            property string tab: "freq"
            readonly property string activeTab: {
                for (const t of root.tabs) if (t.key === tab) return tab
                return root.tabs.length ? root.tabs[0].key : ""
            }

            headerText: "System Monitor"
            detailsText: root.cpu ? root.cpu.model : ""
            showCloseButton: true

            Column {
                id: shell
                width: parent.width
                spacing: Theme.spacingM

                M3Tabs {
                    id: tabsBar
                    visible: root.tabs.length > 0
                    width: parent.width
                    model: root.tabs
                    current: pop.activeTab
                    onSelected: key => pop.tab = key
                }

                StyledText {
                    visible: root.snap === null
                    width: parent.width
                    text: root.err
                    wrapMode: Text.WordWrap
                    font.pixelSize: Theme.fontSizeMedium
                    color: Theme.surfaceVariantText
                }

                Flickable {
                    id: flick
                    width: parent.width
                    height: root.popoutHeight - pop.headerHeight - pop.detailsHeight
                            - tabsBar.height - Theme.spacingM * 2 - Theme.spacingXL
                    contentWidth: width
                    contentHeight: pages.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    Column {
                        id: pages
                        width: flick.width
                        spacing: Theme.spacingM

                        // ================================== frequency ====
                        Column {
                            visible: pop.activeTab === "freq" && root.cpu !== null
                            width: parent.width
                            spacing: Theme.spacingM

                            SwitchRow {
                                visible: root.cpu !== null && root.cpu.turboSupported === true
                                width: parent.width
                                icon: "bolt"
                                label: "Turbo boost"
                                checked: root.cpu !== null && root.cpu.turbo === true
                                onToggled: value => root.setTurbo(value)
                            }

                            Headline {
                                width: parent.width
                                icon: "speed"
                                value: root.fmtFreq(root.panelFreq(), false)
                                caption: root.modeLabel() + " frequency"
                                progress: root.freqFraction(root.panelFreq())
                            }

                            Column {
                                width: parent.width
                                spacing: Theme.spacingXS

                                FieldLabel { text: "Profile"; icon: "tune" }
                                SegmentedControl {
                                    width: parent.width
                                    options: root.profileOptions
                                    current: root.activeProfile()
                                    onSelected: value => root.applyPreset(value)
                                }
                            }

                            Column {
                                visible: root.governorOptions.length > 0
                                width: parent.width
                                spacing: Theme.spacingXS

                                FieldLabel { text: "Governor"; icon: "settings_suggest" }
                                SegmentedControl {
                                    width: parent.width
                                    options: root.governorOptions
                                    current: root.cpu ? root.cpu.governor : ""
                                    onSelected: value => root.setGovernor(value)
                                }
                            }

                            Column {
                                visible: root.eppOptions.length > 0
                                width: parent.width
                                spacing: Theme.spacingXS

                                FieldLabel { text: "Energy preference"; icon: "battery_charging_full" }
                                SegmentedControl {
                                    width: parent.width
                                    maxPerRow: 4          // five options -> 3 + 2, wide enough for icons
                                    options: root.eppOptions
                                    current: root.cpu ? root.cpu.epp : ""
                                    onSelected: value => root.setEpp(value)
                                }
                            }

                            Column {
                                visible: root.cpu !== null && root.cpu.hwMax > root.cpu.hwMin
                                         && (root.opt("freqShowMin", true) || root.opt("freqShowMax", true))
                                width: parent.width
                                spacing: Theme.spacingXS

                                FieldLabel { text: "Scaling frequency"; icon: "swap_vert" }

                                SliderRow {
                                    id: minRow
                                    visible: root.opt("freqShowMin", true)
                                    width: parent.width
                                    icon: "vertical_align_bottom"
                                    label: "Minimum"
                                    valueText: root.fmtFreq(minRow.shown, false)
                                    from: root.cpu ? root.cpu.hwMin : 0
                                    to: root.cpu ? root.cpu.hwMax : 1
                                    step: 100000
                                    value: root.cpu ? root.cpu.scalingMin : 0
                                    onReleased: newValue => root.setMin(newValue)
                                }

                                SliderRow {
                                    id: maxRow
                                    visible: root.opt("freqShowMax", true)
                                    width: parent.width
                                    icon: "vertical_align_top"
                                    label: "Maximum"
                                    valueText: root.fmtFreq(maxRow.shown, false)
                                    from: root.cpu ? root.cpu.hwMin : 0
                                    to: root.cpu ? root.cpu.hwMax : 1
                                    step: 100000
                                    value: root.cpu ? Math.min(root.cpu.scalingMax, root.cpu.hwMax) : 0
                                    onReleased: newValue => root.setMax(newValue)
                                }
                            }

                            Column {
                                visible: root.cores.length > 0 && root.opt("freqCores", true)
                                width: parent.width
                                spacing: Theme.spacingXS

                                FieldLabel { text: "Cores"; icon: "developer_board" }

                                Grid {
                                    width: parent.width
                                    columns: root.coreColumns
                                    columnSpacing: Theme.spacingM
                                    rowSpacing: Theme.spacingXS

                                    Repeater {
                                        model: root.cores.length
                                        delegate: StatRow {
                                            width: (pages.width - (root.coreColumns - 1) * Theme.spacingM) / root.coreColumns
                                            label: "C" + root.coreId(index)
                                            value: root.fmtFreq(root.coreFreq(index), false)
                                            progress: root.freqFraction(root.coreFreq(index))
                                        }
                                    }
                                }
                            }
                        }

                        // ================================ temperature ====
                        Column {
                            visible: pop.activeTab === "temp" && root.cpu !== null
                            width: parent.width
                            spacing: Theme.spacingM

                            Headline {
                                width: parent.width
                                icon: "thermostat"
                                value: root.fmtTemp(root.pkgTemp(), false)
                                caption: "CPU package"
                                progress: root.pkgTemp() === null ? -1 : root.clamp100(root.pkgTemp() / 1000)
                            }

                            Column {
                                visible: root.tempCoreList().length > 0
                                width: parent.width
                                spacing: Theme.spacingXS

                                FieldLabel { text: "Cores"; icon: "developer_board" }

                                Repeater {
                                    model: root.tempCoreList().length
                                    delegate: StatRow {
                                        width: pages.width
                                        icon: "thermostat"
                                        label: "Core " + (root.tempCoreList()[index] ? root.tempCoreList()[index].id : index)
                                        value: root.tempCoreList()[index] ? root.fmtTemp(root.tempCoreList()[index].mc, false) : "–"
                                        progress: root.tempCoreList()[index] ? root.clamp100(root.tempCoreList()[index].mc / 1000) : -1
                                    }
                                }
                            }

                            StyledText {
                                visible: root.tempCoreList().length === 0
                                width: parent.width
                                text: "This CPU only reports a package temperature."
                                wrapMode: Text.WordWrap
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceVariantText
                            }
                        }

                        // ===================================== usage =====
                        Column {
                            visible: pop.activeTab === "usage" && root.cpu !== null
                            width: parent.width
                            spacing: Theme.spacingM

                            Headline {
                                width: parent.width
                                icon: "memory"
                                value: Math.round(root.usageAll) + "%"
                                caption: "CPU usage"
                                progress: root.usageAll
                            }

                            Column {
                                visible: root.cores.length > 0
                                width: parent.width
                                spacing: Theme.spacingXS

                                FieldLabel { text: "Cores"; icon: "developer_board" }

                                Grid {
                                    width: parent.width
                                    columns: root.coreColumns
                                    columnSpacing: Theme.spacingM
                                    rowSpacing: Theme.spacingXS

                                    Repeater {
                                        model: root.cores.length
                                        delegate: StatRow {
                                            width: (pages.width - (root.coreColumns - 1) * Theme.spacingM) / root.coreColumns
                                            label: "C" + root.coreId(index)
                                            value: Math.round(root.coreUsage(index)) + "%"
                                            progress: root.coreUsage(index)
                                        }
                                    }
                                }
                            }
                        }

                        // ======================================= RAM =====
                        Column {
                            visible: pop.activeTab === "mem" && root.mem !== null
                            width: parent.width
                            spacing: Theme.spacingM

                            Headline {
                                width: parent.width
                                icon: "developer_board"
                                value: root.fmtBytes(root.memUsedB(), root.opt("memScale", "auto"), true)
                                caption: "of " + root.fmtBytes(root.memTotalB(), root.opt("memScale", "auto"), true) + " used"
                                progress: root.memPct()
                            }

                            Column {
                                width: parent.width
                                spacing: Theme.spacingXS

                                StatRow {
                                    width: parent.width
                                    icon: "memory"
                                    label: "Used"
                                    value: root.fmtBytes(root.memUsedB(), root.opt("memScale", "auto"), true)
                                }
                                StatRow {
                                    width: parent.width
                                    icon: "check_circle"
                                    label: "Available"
                                    value: root.mem ? root.fmtBytes(root.mem.avail * 1024, root.opt("memScale", "auto"), true) : "–"
                                }
                                StatRow {
                                    width: parent.width
                                    icon: "developer_board"
                                    label: "Total"
                                    value: root.fmtBytes(root.memTotalB(), root.opt("memScale", "auto"), true)
                                }
                                StatRow {
                                    visible: root.mem !== null && root.mem.swapTotal > 0
                                    width: parent.width
                                    icon: "swap_horiz"
                                    label: "Swap"
                                    value: root.mem ? root.fmtBytesPair((root.mem.swapTotal - root.mem.swapFree) * 1024, root.mem.swapTotal * 1024, root.opt("memScale", "auto"), true) : ""
                                    progress: root.mem && root.mem.swapTotal > 0 ? 100 * (root.mem.swapTotal - root.mem.swapFree) / root.mem.swapTotal : -1
                                }
                            }
                        }

                        // ======================================= GPU =====
                        Column {
                            visible: pop.activeTab === "gpu" && root.gpus.length > 0
                            width: parent.width
                            spacing: Theme.spacingL

                            Repeater {
                                model: root.gpus.length

                                delegate: Column {
                                    id: gpuCol
                                    readonly property var g: root.gpus[index] ? root.gpus[index] : null

                                    width: pages.width
                                    spacing: Theme.spacingXS

                                    Headline {
                                        width: parent.width
                                        icon: "auto_awesome_mosaic"
                                        value: gpuCol.g ? gpuCol.g.name : ""
                                        caption: gpuCol.g ? (root.gpuAsleep(gpuCol.g)
                                                 ? gpuCol.g.driver + " · powered down (not woken to read stats)"
                                                 : gpuCol.g.driver) : ""
                                        progress: gpuCol.g && gpuCol.g.usage !== null ? gpuCol.g.usage : -1
                                    }

                                    StatRow {
                                        visible: gpuCol.g !== null && gpuCol.g.usage !== null
                                        width: parent.width
                                        icon: "show_chart"
                                        label: "Usage"
                                        value: gpuCol.g && gpuCol.g.usage !== null ? gpuCol.g.usage + "%" : ""
                                    }
                                    StatRow {
                                        visible: gpuCol.g !== null && gpuCol.g.vramTotal !== null && gpuCol.g.vramTotal > 0
                                        width: parent.width
                                        icon: "developer_board"
                                        label: "VRAM"
                                        value: gpuCol.g && gpuCol.g.vramTotal > 0 ? root.fmtBytesPair(gpuCol.g.vramUsed, gpuCol.g.vramTotal, "auto", true) : ""
                                        progress: gpuCol.g ? root.gpuVramPct(gpuCol.g) : -1
                                    }
                                    StatRow {
                                        visible: gpuCol.g !== null && gpuCol.g.temp !== null
                                        width: parent.width
                                        icon: "thermostat"
                                        label: "Temperature"
                                        value: gpuCol.g ? root.fmtTemp(gpuCol.g.temp, false) : ""
                                    }
                                    StatRow {
                                        visible: gpuCol.g !== null && (gpuCol.g.fanRpm !== null || gpuCol.g.fanPct !== null)
                                        width: parent.width
                                        icon: "mode_fan"
                                        label: "Fan"
                                        value: gpuCol.g ? ((gpuCol.g.fanRpm !== null ? gpuCol.g.fanRpm + " RPM" : "")
                                               + (gpuCol.g.fanRpm !== null && gpuCol.g.fanPct !== null ? "  " : "")
                                               + (gpuCol.g.fanPct !== null ? gpuCol.g.fanPct + "%" : "")) : ""
                                    }
                                    StatRow {
                                        visible: gpuCol.g !== null && gpuCol.g.freq !== null
                                        width: parent.width
                                        icon: "speed"
                                        label: "Clock"
                                        value: gpuCol.g && gpuCol.g.freq !== null ? gpuCol.g.freq + " MHz" : ""
                                    }
                                    StatRow {
                                        visible: gpuCol.g !== null && gpuCol.g.powerW !== null
                                        width: parent.width
                                        icon: "bolt"
                                        label: "Power"
                                        value: gpuCol.g && gpuCol.g.powerW !== null ? gpuCol.g.powerW.toFixed(1) + " W" : ""
                                    }
                                }
                            }
                        }

                        // ====================================== fans =====
                        Column {
                            visible: pop.activeTab === "fans" && root.fans.length > 0
                            width: parent.width
                            spacing: Theme.spacingM

                            Headline {
                                width: parent.width
                                icon: "mode_fan"
                                value: root.fanRpm() === null ? "–" : Math.round(root.fanRpm()) + " RPM"
                                caption: root.opt("fansDisplay", "max") === "avg" ? "Average fan speed" : "Fastest fan"
                            }

                            Column {
                                width: parent.width
                                spacing: Theme.spacingXS

                                Repeater {
                                    model: root.fans.length
                                    delegate: StatRow {
                                        width: pages.width
                                        icon: "mode_fan"
                                        label: root.fans[index] ? root.fans[index].label : ""
                                        value: root.fans[index] ? root.fans[index].rpm + " RPM" : ""
                                    }
                                }
                            }
                        }

                        // ====================================== disk =====
                        Column {
                            visible: pop.activeTab === "disk" && root.disks.length > 0
                            width: parent.width
                            spacing: Theme.spacingM

                            Headline {
                                width: parent.width
                                icon: "storage"
                                value: root.diskSel() ? Math.round(root.diskPct(root.diskSel())) + "% used" : "–"
                                caption: root.diskSel()
                                         ? root.diskSel().mount + " · "
                                           + root.fmtBytesPair(root.diskSel().used, root.diskSel().used + root.diskSel().avail, root.opt("diskScale", "auto"), true)
                                         : ""
                                progress: root.diskSel() ? root.diskPct(root.diskSel()) : -1
                            }

                            Column {
                                width: parent.width
                                spacing: Theme.spacingXS

                                FieldLabel { text: "Filesystems"; icon: "storage" }

                                Repeater {
                                    model: root.disks.length
                                    delegate: StatRow {
                                        readonly property var d: root.disks[index] ? root.disks[index] : null
                                        width: pages.width
                                        icon: "storage"
                                        label: d ? d.mount : ""
                                        value: d ? root.fmtBytesPair(d.used, d.used + d.avail, root.opt("diskScale", "auto"), true) : ""
                                        progress: d ? root.diskPct(d) : -1
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
