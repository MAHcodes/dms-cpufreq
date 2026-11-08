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

    // Hero card for the top of each tab. Inline (rather than a separate file) so
    // an already-running shell can load it without a directory rescan/restart.
    component HeroCard: StyledRect {
        id: hl

        property string icon: ""
        property string title: ""
        property string value: ""
        property string caption: ""
        property real progress: -1          // 0..100, negative hides the bar

        width: parent ? parent.width : 0
        height: col.implicitHeight + Theme.spacingL * 2
        radius: Theme.cornerRadiusL
        color: Theme.primaryContainer

        Column {
            id: col
            x: Theme.spacingL
            y: Theme.spacingL
            width: parent.width - Theme.spacingL * 2
            spacing: Theme.spacingS

            StyledText {
                visible: hl.title !== ""
                text: hl.title
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.Bold
                color: Theme.onPrimaryContainer
                opacity: 0.8
            }

            Row {
                id: head
                width: parent.width
                spacing: Theme.spacingM

                Rectangle {
                    width: 44
                    height: 44
                    radius: 22
                    color: Qt.rgba(Theme.onPrimaryContainer.r, Theme.onPrimaryContainer.g,
                                   Theme.onPrimaryContainer.b, 0.12)

                    DankIcon {
                        anchors.centerIn: parent
                        name: hl.icon
                        size: Theme.iconSize
                        color: Theme.onPrimaryContainer
                    }
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter

                    StyledText {
                        text: hl.value
                        font.pixelSize: Theme.fontSizeXXLarge
                        font.weight: Font.Bold
                        color: Theme.onPrimaryContainer
                        elide: Text.ElideRight
                        width: Math.min(implicitWidth, head.width - 44 - Theme.spacingM)
                    }
                    StyledText {
                        text: hl.caption
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.onPrimaryContainer
                        opacity: 0.8
                        elide: Text.ElideRight
                        width: Math.min(implicitWidth, head.width - 44 - Theme.spacingM)
                    }
                }
            }

            Meter {
                visible: hl.progress >= 0
                width: parent.width
                value: hl.progress
            }
        }
    }

    // Material 3 filled section card: an optional small header over a padded
    // body column. Children of a `SectionCard { ... }` land in that body.
    component SectionCard: StyledRect {
        id: card

        property string title: ""
        property string icon: ""
        property string caption: ""
        property real bodySpacing: Theme.spacingXS

        default property alias content: body.data

        width: parent ? parent.width : 0
        height: layout.implicitHeight + Theme.spacingM * 2
        radius: Theme.cornerRadiusL
        color: Theme.surfaceContainer

        Column {
            id: layout
            x: Theme.spacingM
            y: Theme.spacingM
            width: card.width - Theme.spacingM * 2
            spacing: Theme.spacingS

            Row {
                visible: card.title !== "" || card.icon !== ""
                width: parent.width
                spacing: Theme.spacingS

                DankIcon {
                    visible: card.icon !== ""
                    name: card.icon
                    size: Theme.iconSize - 8
                    color: Theme.primary
                    anchors.verticalCenter: parent.verticalCenter
                }
                StyledText {
                    visible: card.title !== ""
                    text: card.title
                    font.pixelSize: Theme.fontSizeSmall
                    font.weight: Font.Bold
                    color: Theme.surfaceVariantText
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            StyledText {
                visible: card.caption !== ""
                width: parent.width
                text: card.caption
                wrapMode: Text.WordWrap
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceVariantText
            }

            Column {
                id: body
                width: parent.width
                spacing: card.bodySpacing
            }
        }
    }

    // Installed by install.sh (root-owned, referenced by the polkit policy).
    readonly property string ctl: "/usr/local/bin/dms-cpufreqctl"

    // ===================================================== metric registry ==
    // freq/temp/usage used to be three separate metrics; they merged into one
    // "cpu" metric (one tab, one settings page, one bar icon). Their old
    // settings keys are still read as fallbacks (see optL).
    readonly property var metricKeys: ["cpu", "mem", "gpu", "fans", "disk", "bat"]
    readonly property var metricIcons: ({
        cpu: "memory",
        mem: "developer_board",
        gpu: "auto_awesome_mosaic",
        fans: "mode_fan",
        disk: "storage",
        bat: "battery_full"
    })
    readonly property var metricLabels: ({
        cpu: "CPU", mem: "RAM", gpu: "GPU", fans: "Fans", disk: "Disk", bat: "Battery"
    })
    readonly property var platformIcons: ({
        performance: "rocket_launch", "balanced-performance": "speed", balanced: "balance",
        "low-power": "eco", quiet: "volume_off", cool: "ac_unit"
    })
    readonly property var platformShort: ({
        "balanced-performance": "Bal. perf", "low-power": "Low power"
    })
    readonly property var behaviourLabels: ({
        auto: "Auto", "inhibit-charge": "Pause", "force-discharge": "Discharge"
    })
    readonly property var behaviourIcons: ({
        auto: "autorenew", "inhibit-charge": "pause_circle", "force-discharge": "trending_down"
    })
    readonly property var chargePresets: [
        { label: "Full", value: "full", icon: "battery_full", start: 96, stop: 100 },
        { label: "Balanced", value: "balanced", icon: "balance", start: 75, stop: 80 },
        { label: "Lifespan", value: "lifespan", icon: "eco", start: 50, stop: 60 }
    ]
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

    // setting with a legacy fallback key (used by the merged cpu metric)
    function optL(key, legacyKey, def) {
        const v = pluginData ? pluginData[key] : undefined
        return (v === undefined || v === null || v === "") ? opt(legacyKey, def) : v
    }

    // GPU popout sections are individually toggleable (see CpuFreqSettings).
    function gpuShow(section) { return opt("gpuShow" + section, true) !== false }

    function intOpt(key, def, legacyKey) {
        let raw = opt(key, undefined)
        if ((raw === undefined || raw === null || raw === "") && legacyKey)
            raw = opt(legacyKey, undefined)
        const n = parseInt(raw)
        return (isNaN(n) || n < 1) ? def : n
    }

    // Column count for each per-core grid, each configured in its own tab.
    // `coreColumns` was the old shared setting; keep it as a fallback so an
    // existing choice is not lost.
    property int freqColumns: intOpt("freqColumns", 2, "coreColumns")
    property int tempColumns: intOpt("tempColumns", 3)
    property int usageColumns: intOpt("usageColumns", 2, "coreColumns")

    // ========================================================== state ======
    property var snap: null                      // last parsed status
    property string err: "Waiting for data. If this stays empty, the helper is not installed: run install.sh from this plugin's folder (see README)."
    property var prevStat: null
    property real usageAll: 0
    property var usageById: ({})
    property var pendingApply: []
    property var current: ({ cmd: "apply", args: [], ok: "" })

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
    readonly property var bats: snap && snap.bats ? snap.bats : []
    readonly property bool onAc: snap != null && snap.ac === true

    // TLP state is polled separately (and slower) than the cheap sysfs status
    property var tlpInfo: null
    property var behaviourOptions: []
    property var platformOptions: []
    readonly property bool tlpInstalled: tlpInfo != null && tlpInfo.installed === true

    function assignStable(prop, val) {
        const s = JSON.stringify(val)
        if (_sig[prop] === s) return
        _sig[prop] = s
        root[prop] = val
    }

    // ===================================================== availability ====
    function available(key) {
        switch (key) {
        case "cpu": return cpu != null
        case "mem": return mem != null
        case "gpu": return gpus.length > 0
        case "fans": return fans.length > 0
        case "disk": return disks.length > 0
        case "bat": return bats.length > 0
        }
        return false
    }

    function barShown(key) {
        if (!available(key)) return false
        return key === "cpu" ? optL("cpuBar", "freqBar", true) : opt(key + "Bar", false)
    }
    function tabShown(key) {
        if (!available(key)) return false
        return key === "cpu"
            ? (optL("cpuTab", "freqTab", true) || opt("tempTab", true) || opt("usageTab", true))
            : opt(key + "Tab", true)
    }
    function barIconShown(key) {
        return key === "cpu" ? optL("cpuIcon", "freqIcon", true) : opt(key + "Icon", true)
    }

    // optional divider between bar entries (see General settings)
    function barSep() { return opt("barSeparator", "none") }

    // which helper sections are worth collecting (nvidia-smi etc. only when needed)
    function sections() {
        const need = k => (k === "cpu"
                ? (optL("cpuBar", "freqBar", true) || optL("cpuTab", "freqTab", true)
                   || opt("tempTab", true) || opt("usageTab", true))
                : (opt(k + "Bar", false) || opt(k + "Tab", true)))
        const s = []
        if (need("cpu") || need("bat")) s.push("cpu")
        if (need("mem")) s.push("mem")
        if (need("gpu")) s.push("gpu")
        if (need("fans")) s.push("fans")
        if (need("disk")) s.push("disk")
        if (need("bat")) s.push("bat")
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

    // ============================================================ battery ==
    // sysfs reports energy in uWh, power in uW, voltage in uV, temperature in 0.1 C
    function metricIcon(key) { return key === "bat" ? batIcon() : metricIcons[key] }

    function batTotals() {
        const t = { en: 0, ef: 0, ed: 0, pw: 0, target: 0, cap: 0, n: 0, haveEnergy: bats.length > 0 }
        for (const b of bats) {
            t.n++
            t.cap += b.capacity != null ? b.capacity : 0
            if (b.energyNow != null && b.energyFull != null) {
                t.en += b.energyNow
                t.ef += b.energyFull
                const lim = (b.hasStop && b.stop != null && b.stop > 0 && b.stop < 100) ? b.stop : 100
                t.target += b.energyFull * lim / 100
            } else {
                t.haveEnergy = false
            }
            if (b.energyDesign != null) t.ed += b.energyDesign
            if (b.powerNow != null) t.pw += b.powerNow
        }
        return t
    }

    function batPct() {
        const t = batTotals()
        if (t.haveEnergy && t.ef > 0) return clamp100(100 * t.en / t.ef)
        return t.n > 0 ? clamp100(t.cap / t.n) : 0
    }

    function batStatus() {
        let first = ""
        for (const b of bats) {
            if (b.status === "Charging") return "Charging"
            if (first === "") first = b.status
        }
        for (const b of bats) if (b.status === "Discharging") return "Discharging"
        return first !== "" ? first : "Unknown"
    }

    // hours until empty (discharging) or until the charge limit (charging); -1 when unknown
    function batEtaH() {
        const t = batTotals()
        if (!t.haveEnergy || t.pw <= 0) return -1
        const s = batStatus()
        if (s === "Discharging") return t.en / t.pw
        if (s === "Charging") return Math.max(0, t.target - t.en) / t.pw
        return -1
    }

    function fmtDuration(h, short) {
        if (h < 0 || h > 99) return "–"
        const m = Math.round(h * 60)
        const hh = Math.floor(m / 60)
        const mm = m % 60
        if (short) return hh + ":" + (mm < 10 ? "0" : "") + mm
        return hh > 0 ? hh + " h " + mm + " min" : mm + " min"
    }

    function fmtWh(uwh) { return uwh == null ? "–" : (uwh / 1e6).toFixed(1) + " Wh" }
    function fmtW(uw) { return uw == null ? "–" : (uw / 1e6).toFixed(1) + " W" }
    function fmtV(uv) { return uv == null ? "–" : (uv / 1e6).toFixed(2) + " V" }

    function batHealth(b) {
        return b && b.energyFull != null && b.energyDesign > 0 ? clamp100(100 * b.energyFull / b.energyDesign) : -1
    }

    function batIcon() {
        if (!bats.length) return "battery_unknown"
        const s = batStatus()
        const p = batPct()
        if (s === "Charging") return "battery_charging_full"
        if (s === "Discharging" && p < 10) return "battery_alert"
        if (p >= 95) return "battery_full"
        if (p >= 80) return "battery_6_bar"
        if (p >= 65) return "battery_5_bar"
        if (p >= 50) return "battery_4_bar"
        if (p >= 35) return "battery_3_bar"
        if (p >= 20) return "battery_2_bar"
        return p >= 8 ? "battery_1_bar" : "battery_0_bar"
    }

    function batCaption() {
        if (!bats.length) return ""
        const s = batStatus()
        const eta = batEtaH()
        const t = batTotals()
        const parts = [s]
        if (eta >= 0) {
            if (s === "Discharging") parts.push(fmtDuration(eta, false) + " left")
            else parts.push(fmtDuration(eta, false) + " to " + chargeTargetText())
        } else if (s === "Not charging" || s === "Full") {
            const lim = chargeLimitText()
            if (lim !== "") parts.push(lim)
        }
        if (t.pw > 0) parts.push(fmtW(t.pw))
        return parts.join(" · ")
    }

    function chargeLimitText() {
        for (const b of bats) if (b.hasStop && b.stop != null && b.stop < 100) return "limit " + b.stop + "%"
        return ""
    }
    function chargeTargetText() {
        for (const b of bats) if (b.hasStop && b.stop != null && b.stop < 100) return b.stop + "%"
        return "full"
    }

    function batName(i) {
        return bats.length > 1 && bats[i] ? " · " + bats[i].name : ""
    }

    function chargePreset(b) {
        if (!b || b.stop == null) return ""
        for (const p of chargePresets) {
            if (b.stop === p.stop && (!b.hasStart || b.start === p.start)) return p.value
        }
        return ""
    }

    function chargeCaption(b) {
        if (!tlpInstalled)
            return "TLP was not found: limits are written to the kernel directly and last until the next reboot."
        return opt("batPersist", true)
            ? "Saved to the TLP config, so the limit survives reboots."
            : "Temporary: TLP restores the configured limit at the next boot."
    }

    function tlpRange(which, def) {
        const v = tlpInfo ? tlpInfo[which] : null
        return (v === null || v === undefined) ? def : v
    }

    function tlpHasFeature(f) {
        return tlpInstalled && ((tlpInfo.features || "").indexOf(f) >= 0)
    }

    function tlpAtLeast(maj, min) {
        const t = tlpInfo
        return !!t && t.installed === true && (t.major > maj || (t.major === maj && t.minor >= min))
    }

    // ============================================================ metrics ==
    function freqList() {
        return cores.map(c => c.cur).filter(v => v != null && v !== undefined)
    }
    function panelFreq(m) {
        const f = freqList()
        if (!f.length) return null
        const mode = m || opt("freqMode", "avg")
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
        if (cpu.temp.pkg != null) return cpu.temp.pkg
        if (cpu.temp.cores.length) return Math.max.apply(null, cpu.temp.cores.map(t => t.mc))
        return null
    }
    function tempCoreList() { return cpu && cpu.temp ? cpu.temp.cores : [] }

    function memKB(kb) { return (kb === null || kb === undefined) ? 0 : kb * 1024 }
    function memUsedB() { return mem ? (mem.total - mem.avail) * 1024 : 0 }
    function memTotalB() { return mem ? mem.total * 1024 : 0 }
    function memPct() { return mem && mem.total > 0 ? 100 * (mem.total - mem.avail) / mem.total : 0 }
    function memCachedKB() { return mem ? (mem.cached || 0) + (mem.sreclaimable || 0) : 0 }

    function gpuSel() {
        if (!gpus.length) return null
        const i = parseInt(opt("gpuIndex", "0"))
        return gpus[Math.min(isNaN(i) ? 0 : i, gpus.length - 1)]
    }
    function gpuVramPct(g) { return g && g.vramTotal > 0 ? 100 * g.vramUsed / g.vramTotal : 0 }
    function gpuAsleep(g) { return g.state === "suspended" || g.state === "suspending" }
    function fmtMhz(cur, max) {
        if (cur === null || cur === undefined) return "–"
        let s = cur + " MHz"
        if (max != null && max !== undefined && max !== cur) s += " / " + max + " MHz"
        return s
    }
    function fmtWatts(v) {
        return (v === null || v === undefined) ? "–" : v.toFixed(1) + " W"
    }
    function gpuPowerText(g) {
        if (!g || g.powerW === null || g.powerW === undefined) return "–"
        let s = g.powerW.toFixed(1) + " W"
        if (g.powerLimitW != null && g.powerLimitW !== undefined) s += " / " + g.powerLimitW.toFixed(0) + " W limit"
        return s
    }
    function gpuPowerLimits(g) {
        if (!g) return ""
        const p = []
        if (g.powerDefaultW != null && g.powerDefaultW !== undefined) p.push("default " + g.powerDefaultW.toFixed(0) + " W")
        if (g.powerMinW != null && g.powerMinW !== undefined) p.push("min " + g.powerMinW.toFixed(0) + " W")
        if (g.powerMaxW != null && g.powerMaxW !== undefined) p.push("max " + g.powerMaxW.toFixed(0) + " W")
        return p.join(" · ")
    }
    function gpuPcieText(g) {
        if (!g) return "–"
        const one = (gen, width) => {
            if (gen === null || gen === undefined) return width === null || width === undefined ? "" : "x" + width
            return "Gen " + gen + (width === null || width === undefined ? "" : " x" + width)
        }
        const cur = one(g.pcieGen, g.pcieWidth)
        const max = one(g.pcieGenMax, g.pcieWidthMax)
        if (!cur) return "–"
        return (max && max !== cur) ? cur + " (max " + max + ")" : cur
    }
    function gpuThrottle(g) {
        return g && g.throttle ? g.throttle : "None"
    }

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

    // Values a bar entry can show; several can be on at once (see the settings).
    // Until any of the new <key>BarShow<Value> toggles is touched, the old
    // single-choice settings keep deciding, so an existing setup carries over.
    // `primary` is the fresh-install default.
    readonly property var barValueDefs: ({
        cpu: { primary: "avg", values: ["min", "avg", "max", "temp", "usage"] },
        mem: { legacy: ["memDisplay", "percent"], primary: "percent", values: ["percent", "used", "available", "free", "used_total"] },
        gpu: { legacy: ["gpuDisplay", "usage"], primary: "usage", values: ["usage", "temp", "vram", "power", "clock"] },
        disk: { legacy: ["diskDisplay", "percent"], primary: "percent", values: ["percent", "used", "free", "used_total"] },
        bat: { legacy: ["batDisplay", "percent"], primary: "percent", values: ["percent", "time", "power", "energy"] }
    })

    function barValuesOn(key) {
        const def = barValueDefs[key]
        if (!def) return [key]              // fans: a single value
        let touched = false
        for (const k in (pluginData || {})) {
            if (k.indexOf(key + "BarShow") === 0) { touched = true; break }
        }
        const out = []
        if (!touched) {
            if (key === "cpu") {
                // migrate: what the old freq/temp/usage metrics showed in the bar
                if (optL("cpuBar", "freqBar", true)) {
                    let f = false
                    for (const k in (pluginData || {})) {
                        if (k.indexOf("freqBarShow") === 0) { f = true; break }
                    }
                    if (f) {
                        for (const v of ["min", "avg", "max"])
                            if (opt("freqBarShow" + cap(v), v === "avg") === true) out.push(v)
                    } else out.push(opt("freqMode", "avg"))
                }
                if (opt("tempBar", false)) out.push("temp")
                if (opt("usageBar", false)) out.push("usage")
                return out.length ? out : [def.primary]
            }
            for (const v of def.values) {
                if (opt(def.legacy[0], def.legacy[1]) === v) out.push(v)
            }
            return out.length ? out : [def.primary]
        }
        for (const v of def.values) {
            if (opt(key + "BarShow" + cap(v), v === def.primary) === true) out.push(v)
        }
        return out
    }

    // [number, unit] for one value of one bar entry. Unit strings carry the
    // spacing used horizontally ("%"/"°C" hug the number, " GHz" does not).
    function barPartsFor(key, val) {
        const u = x => (key === "cpu"
            ? optL("cpuShowUnit", "freqShowUnit", true)
            : opt(key + "ShowUnit", true)) ? x : ""
        if (key === "cpu") {
            if (val === "temp") {
                const mc = pkgTemp()
                if (mc === null) return ["–", ""]
                const c = mc / 1000
                return opt("tempScale", "C") === "F"
                    ? [String(Math.round(c * 9 / 5 + 32)), u("°F")]
                    : [String(Math.round(c)), u("°C")]
            }
            if (val === "usage") return [String(Math.round(usageAll)), u("%")]
            const khz = panelFreq(val)
            if (khz === null) return ["–", ""]
            if (opt("freqScale", "GHz") === "MHz") return [String(Math.round(khz / 1000)), u(" MHz")]
            return [(khz / 1e6).toFixed(parseInt(opt("freqPrecision", "1"))), u(" GHz")]
        }
        if (key === "mem") {
            const sc = opt("memScale", "auto")
            if (val === "percent") return [String(Math.round(memPct())), u("%")]
            if (val === "used" || val === "available" || val === "free") {
                const b = val === "used" ? memUsedB() : memKB(val === "available" ? mem.avail : mem.free)
                const un = pickUnit(b, sc)
                return [fmtNum(b / unitDiv(un)), u(" " + un)]
            }
            const un = pickUnit(memTotalB(), sc)
            return [fmtNum(memUsedB() / unitDiv(un)) + "/" + fmtNum(memTotalB() / unitDiv(un)), u(" " + un)]
        }
        if (key === "gpu") {
            const g = gpuSel()
            if (!g) return ["–", ""]
            if (val === "temp") {
                if (g.temp === null || g.temp === undefined) return ["–", ""]
                const c = g.temp / 1000
                return opt("tempScale", "C") === "F"
                    ? [String(Math.round(c * 9 / 5 + 32)), u("°F")]
                    : [String(Math.round(c)), u("°C")]
            }
            if (val === "vram") return g.vramTotal > 0 ? [String(Math.round(gpuVramPct(g))), u("%")] : ["–", ""]
            if (val === "power") return (g.powerW === null || g.powerW === undefined) ? ["–", ""] : [g.powerW.toFixed(1), u(" W")]
            if (val === "clock") return (g.freq === null || g.freq === undefined) ? ["–", ""] : [String(g.freq), u(" MHz")]
            return g.usage === null ? ["–", ""] : [String(g.usage), u("%")]
        }
        if (key === "fans") {
            const r = fanRpm()
            return r === null ? ["–", ""] : [String(Math.round(r)), u(" RPM")]
        }
        if (key === "disk") {
            const d = diskSel()
            if (!d) return ["–", ""]
            const sc = opt("diskScale", "auto")
            if (val === "percent") return [String(Math.round(diskPct(d))), u("%")]
            if (val === "used" || val === "free") {
                const b = val === "used" ? d.used : d.avail
                const un = pickUnit(b, sc)
                return [fmtNum(b / unitDiv(un)), u(" " + un)]
            }
            const un = pickUnit(d.used + d.avail, sc)
            return [fmtNum(d.used / unitDiv(un)) + "/" + fmtNum((d.used + d.avail) / unitDiv(un)), u(" " + un)]
        }
        if (key === "bat") {
            if (!bats.length) return ["–", ""]
            const t = batTotals()
            if (val === "time") return [fmtDuration(batEtaH(), true), ""]
            if (val === "power") return t.pw > 0 ? [(t.pw / 1e6).toFixed(1), u(" W")] : ["–", ""]
            if (val === "energy") return t.haveEnergy ? [(t.en / 1e6).toFixed(1), u(" Wh")] : ["–", ""]
            return [String(Math.round(batPct())), u("%")]
        }
        return ["", ""]
    }

    // Every bar item: one per (metric × shown value), all sharing the metric's
    // icon, so a multi-value metric reads as separate entries.
    // `used/total` stays one item because it is one value.
    function barItems() {
        const out = []
        for (const key of metricKeys) {
            if (!barShown(key)) continue
            for (const v of barValuesOn(key)) {
                const p = barPartsFor(key, v)
                out.push({ key: key, icon: metricIcon(key), num: p[0], unit: p[1] })
            }
        }
        return out
    }

    readonly property var barItemsList: barItems()

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

        if (j.bats) {
            let opts = []
            for (const b of j.bats) {
                if (b.behaviours && b.behaviours.length > 1) {
                    opts = buildOptions(b.behaviours, behaviourIcons, behaviourLabels)
                    break
                }
            }
            assignStable("behaviourOptions", opts)
        }

        snap = j
        err = ""
        refreshTabs()
    }

    function handleTlp(text) {
        let j
        try {
            j = JSON.parse(text)
        } catch (e) {
            return
        }
        if (!j.tlp) return
        assignStable("platformOptions", buildOptions(j.tlp.platformChoices || [], platformIcons, platformShort))
        assignStable("tlpInfo", j.tlp)
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

    Process {
        id: tlpProc
        command: [root.ctl, "status", "tlp"]
        stdout: StdioCollector {
            onStreamFinished: root.handleTlp(this.text)
        }
    }

    function refreshTlp() {
        if (!tlpProc.running) tlpProc.running = true
    }

    // TLP configuration changes rarely; the popout also refreshes it when it opens
    // and after every change made from here.
    Timer {
        interval: 30000
        running: root.bats.length > 0 && (root.opt("batBar", false) || root.opt("batTab", true))
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refreshTlp()
    }

    Timer {
        interval: Math.max(250, parseInt(root.opt("refreshInterval", "2000")) || 2000)
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

    // Everything privileged goes through one queue: { cmd, args, ok } becomes
    // `pkexec dms-cpufreqctl <cmd> <args...>`. `ok` is an optional success toast.
    function run(cmd, args, ok) {
        pendingApply.push({ cmd: cmd, args: args, ok: ok || "" })
        if (!applyProc.running) nextApply()
    }

    function apply(args) { run("apply", args, "") }

    function nextApply() {
        if (!pendingApply.length) return
        current = pendingApply.shift()
        applyProc.command = ["pkexec", ctl, current.cmd].concat(current.args)
        applyProc.running = true
    }

    function applyDone(code, errText) {
        if (code === 0) {
            if (current.cmd === "apply") remember(current.args)
            if (current.ok) ToastService?.showInfo("System Monitor: " + current.ok)
        } else if (code === 126 || code === 127) {
            ToastService?.showInfo("System Monitor: authentication cancelled or failed")
        } else {
            const first = (errText || "").split("\n")[0].replace(/^dms-cpufreqctl:\s*/, "")
            ToastService?.showInfo("System Monitor: " + (first || "change failed"))
        }
        if (current.cmd !== "apply") refreshTlp()
        if (!statusProc.running) statusProc.running = true
        nextApply()
    }

    // Switching the TLP profile (TLP 1.9+) does not need root when tlp-pd is running:
    // tlpctl talks to the daemon, which authorizes the active session itself.
    Process {
        id: profileProc
        property string wanted: ""
        stderr: StdioCollector { id: profileErr }
        onExited: (code, status) => {
            if (code !== 0) root.run("tlp-mode", [profileProc.wanted], "TLP profile: " + profileProc.wanted)
            else ToastService?.showInfo("System Monitor: TLP profile " + profileProc.wanted)
            root.refreshTlp()
        }
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

    // ================================================ battery / TLP actions ==
    function setTlpProfile(name) {
        if (tlpInfo && tlpInfo.profiles && tlpInfo.pd && tlpInfo.hasCtl) {
            profileProc.wanted = name
            profileProc.command = ["tlpctl", "set", name]
            profileProc.running = true
        } else {
            run("tlp-mode", [name], "TLP profile: " + name)
        }
    }

    function setTlpMode(mode) { run("tlp-mode", [mode], "TLP mode: " + mode) }

    function setCharge(bat, start, stop) {
        run("charge", ["start=" + start, "stop=" + stop, "bat=" + bat,
                       "persist=" + (opt("batPersist", true) ? 1 : 0)],
            "charge limit " + (start > 0 ? start + "-" : "") + stop + "%")
    }

    // keep start below stop: moving one bound drags the other along
    function setChargeStart(b, v) {
        let start = Math.round(v)
        let stop = b.stop != null ? b.stop : 100
        if (start >= stop) {
            stop = Math.min(100, start + 5)
            if (stop - start < 5) start = stop - 5
        }
        setCharge(b.name, start, stop)
    }
    function setChargeStop(b, v) {
        const stop = Math.round(v)
        let start = b.hasStart && b.start != null ? b.start : 0
        if (b.hasStart && start >= stop) start = Math.max(0, stop - 5)
        setCharge(b.name, start, stop)
    }
    function applyChargePreset(b, value) {
        for (const p of chargePresets) if (p.value === value) { setCharge(b.name, p.start, p.stop); return }
    }

    function chargeAction(action, bat) {
        const msg = ({ fullcharge: "charging to full", chargeonce: "charging to the limit once",
                       discharge: "discharging", recalibrate: "recalibration started" })[action]
        run("charge-action", [action, "bat=" + bat], msg)
    }
    function restoreCharge(bat) { run("charge", ["restore", "bat=" + bat], "configured charge limits restored") }
    function setBehaviour(bat, v) { run("behaviour", [v, "bat=" + bat], "charge behaviour: " + v) }

    // TLP tuning: every item is { base | key, label, icon, type, ... }; `base` items exist per profile (_ON_AC/_BAT/_SAV)
    readonly property var tlpGroups: [
        { title: "Processor", icon: "memory", items: [
            { base: "CPU_SCALING_GOVERNOR", label: "CPU governor", icon: "settings_suggest", type: "seg", from: "governors", sav: true },
            { base: "CPU_ENERGY_PERF_POLICY", label: "Energy preference", icon: "battery_charging_full", type: "seg", from: "epps", sav: true },
            { base: "PLATFORM_PROFILE", label: "Platform profile", icon: "tune", type: "seg", from: "platform", sav: true },
            { base: "CPU_BOOST", label: "Turbo boost", icon: "bolt", type: "switch", sav: true },
            { base: "CPU_HWP_DYN_BOOST", label: "HWP dynamic boost", icon: "electric_bolt", type: "switch", sav: true },
            { base: "CPU_MIN_PERF", label: "Minimum performance", icon: "vertical_align_bottom", type: "slider", min: 0, max: 100, unit: "%", def: 0, sav: true },
            { base: "CPU_MAX_PERF", label: "Maximum performance", icon: "vertical_align_top", type: "slider", min: 0, max: 100, unit: "%", def: 100, sav: true }
        ] },
        { title: "Graphics", icon: "auto_awesome_mosaic", items: [
            { base: "AMDGPU_ABM_LEVEL", label: "AMD display power saving", icon: "brightness_medium", type: "seg", sav: true,
              options: [ { label: "Off", value: "0" }, { label: "1", value: "1" }, { label: "2", value: "2" },
                         { label: "3", value: "3" }, { label: "4", value: "4" } ] },
            { base: "RADEON_DPM_PERF_LEVEL", label: "Radeon DPM level", icon: "speed", type: "seg", sav: true,
              options: [ { label: "Auto", value: "auto" }, { label: "Low", value: "low" }, { label: "High", value: "high" } ] }
        ] },
        { title: "Devices", icon: "devices", items: [
            { base: "PCIE_ASPM", label: "PCIe power saving (ASPM)", icon: "settings_ethernet", type: "seg", sav: true,
              options: [ { label: "Default", value: "default" }, { label: "Perf", value: "performance" },
                         { label: "Save", value: "powersave" }, { label: "Max save", value: "powersupersave" } ] },
            { base: "RUNTIME_PM", label: "Runtime power management", icon: "power_settings_new", type: "switch", onValue: "auto", offValue: "on" },
            { base: "WIFI_PWR", label: "Wi-Fi power saving", icon: "wifi", type: "switch", onValue: "on", offValue: "off" },
            { base: "SOUND_POWER_SAVE", label: "Audio power-save timeout", icon: "volume_down", type: "slider", min: 0, max: 60, unit: " s", def: 10 },
            { base: "SATA_LINKPWR", label: "SATA link power", icon: "storage", type: "seg",
              options: [ { label: "Max perf", value: "max_performance" }, { label: "Medium", value: "medium_power" },
                         { label: "Med + DIPM", value: "med_power_with_dipm" }, { label: "Min power", value: "min_power" } ] },
            { base: "AHCI_RUNTIME_PM", label: "AHCI runtime PM", icon: "hard_drive", type: "switch", onValue: "auto", offValue: "on" }
        ] },
        { title: "System", icon: "settings", global: true, items: [
            { key: "TLP_PROFILE_AC", label: "Profile on AC power", icon: "power", type: "seg", minVersion: [1, 10],
              options: [ { label: "Power saver", value: "power-saver", icon: "eco" }, { label: "Balanced", value: "balanced", icon: "balance" },
                         { label: "Performance", value: "performance", icon: "rocket_launch" } ] },
            { key: "TLP_PROFILE_BAT", label: "Profile on battery", icon: "battery_full", type: "seg", minVersion: [1, 10],
              options: [ { label: "Power saver", value: "power-saver", icon: "eco" }, { label: "Balanced", value: "balanced", icon: "balance" },
                         { label: "Performance", value: "performance", icon: "rocket_launch" } ] },
            { key: "USB_AUTOSUSPEND", label: "USB autosuspend", icon: "usb", type: "switch", onValue: "1", offValue: "0" },
            { key: "NMI_WATCHDOG", label: "NMI watchdog", icon: "monitor_heart", type: "switch", onValue: "1", offValue: "0" },
            { key: "WOL_DISABLE", label: "Disable Wake-on-LAN", icon: "lan", type: "switch", onValue: "Y", offValue: "N" }
        ] }
    ]

    readonly property var tuneProfiles: tlpInfo && tlpInfo.profiles
        ? [ { label: "Performance", value: "AC", icon: "rocket_launch" },
            { label: "Balanced", value: "BAT", icon: "balance" },
            { label: "Power saver", value: "SAV", icon: "eco" } ]
        : [ { label: "On AC", value: "AC", icon: "power" },
            { label: "On battery", value: "BAT", icon: "battery_full" } ]

    function tlpKey(item, profile) { return item.base ? item.base + "_ON_" + profile : item.key }

    function tlpItems(group, profile) {
        const out = []
        for (const it of group.items) {
            if (it.minVersion && !tlpAtLeast(it.minVersion[0], it.minVersion[1])) continue
            if (it.base && !group.global && profile === "SAV" && !it.sav) continue
            out.push(it)
        }
        return out
    }

    function tlpOptions(item) {
        if (item.from === "governors") return governorOptions
        if (item.from === "epps") return eppOptions
        if (item.from === "platform") return platformOptions
        return item.options || []
    }

    function tlpConfEntry(key) {
        return tlpInfo && tlpInfo.conf && tlpInfo.conf[key] ? tlpInfo.conf[key] : null
    }
    function tlpValue(key) { const e = tlpConfEntry(key); return e ? e.v : "" }
    function tlpSource(key) { const e = tlpConfEntry(key); return e ? e.f : "" }
    function tlpManaged(key) { return !!(tlpInfo && tlpInfo.managed && tlpInfo.managed.indexOf(key) >= 0) }

    function tlpSet(key, value, label) { run("tlp-conf", [key + "=" + value], label + " saved to TLP config") }
    function tlpReset(keys) { run("tlp-reset", keys, keys.length ? "setting reset to TLP default" : "all plugin TLP settings reset") }

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
                visible: root.barItemsList.length === 0
                text: root.snap ? "–" : "…"
                font.pixelSize: root.barFontSize
                color: root.barTextColor
                anchors.verticalCenter: parent.verticalCenter
            }

            Repeater {
                model: root.barItemsList

                delegate: Row {
                    spacing: 0

                    StyledText {
                        visible: index > 0 && root.barSep() === "none"
                        text: "\u00A0\u00A0"
                        font.pixelSize: root.barFontSize
                        color: root.barTextColor
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    StyledText {
                        visible: index > 0 && root.barSep() === "dot"
                        text: "\u00A0\u00B7\u00A0"
                        font.pixelSize: root.barFontSize
                        color: root.barTextColor
                        opacity: 0.55
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Item {
                        visible: index > 0 && root.barSep() === "line"
                        width: root.barFontSize
                        height: 1
                        anchors.verticalCenter: parent.verticalCenter

                        Rectangle {
                            anchors.centerIn: parent
                            width: 1
                            height: Math.round(root.barFontSize * 1.1)
                            color: root.barTextColor
                            opacity: 0.4
                        }
                    }

                    Row {
                        spacing: Theme.spacingXS
                        anchors.verticalCenter: parent.verticalCenter

                        DankIcon {
                            visible: root.barIconShown(modelData.key)
                            name: modelData.icon
                            size: root.barIconSize
                            color: Theme.primary
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        StyledText {
                            text: modelData.num + modelData.unit
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
                visible: root.barItemsList.length === 0
                text: root.snap ? "–" : "…"
                font.pixelSize: root.barFontSize
                color: root.barTextColor
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Repeater {
                model: root.barItemsList

                delegate: Column {
                    readonly property var nums: modelData.num.split("/")

                    spacing: Theme.spacingXS
                    anchors.horizontalCenter: parent.horizontalCenter

                    StyledText {
                        visible: index > 0 && root.barSep() === "dot"
                        text: "\u00B7"
                        font.pixelSize: Math.max(9, root.barFontSize - 4)
                        color: root.barTextColor
                        opacity: 0.55
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    Rectangle {
                        visible: index > 0 && root.barSep() === "line"
                        width: Math.round(root.barFontSize * 1.5)
                        height: 1
                        color: root.barTextColor
                        opacity: 0.4
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    DankIcon {
                        visible: root.barIconShown(modelData.key)
                        name: modelData.icon
                        size: root.barIconSize
                        color: Theme.primary
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    StyledText {
                        text: nums[0]
                        font.pixelSize: root.barFontSize
                        color: root.barTextColor
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    // a "/" in the number (used/total) splits over lines to fit
                    Repeater {
                        model: nums.length - 1

                        StyledText {
                            text: "/" + nums[index + 1]
                            font.pixelSize: Math.max(9, root.barFontSize - 4)
                            color: root.barTextColor
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }
                    StyledText {
                        visible: modelData.unit !== ""
                        text: modelData.unit.trim()
                        font.pixelSize: Math.max(9, root.barFontSize - 4)
                        color: root.barTextColor
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
            }
        }
    }

    // sub-pages of the Battery tab, each can be hidden in the plugin settings
    readonly property var batPageOptions: {
        const o = [{ label: "Overview", value: "overview", icon: "battery_full" }]
        if (opt("batShowCharging", true)) o.push({ label: "Charging", value: "charging", icon: "bolt" })
        if (opt("batShowTuning", true)) o.push({ label: "Tuning", value: "tuning", icon: "tune" })
        return o
    }

    // ========================================================== popout =====
    popoutWidth: 600
    popoutHeight: 800

    popoutContent: Component {
        PopoutComponent {
            id: pop

            property string tab: "cpu"
            readonly property string activeTab: {
                for (const t of root.tabs) if (t.key === tab) return tab
                return root.tabs.length ? root.tabs[0].key : ""
            }

            // Battery tab: sub-page, which TLP profile the Tuning page edits, and a
            // two-step confirmation for destructive actions ("kind:name", auto-expires)
            property string batPage: "overview"
            property string tuneProfile: "BAT"
            property string confirm: ""
            readonly property string batPageActive: {
                for (const o of root.batPageOptions) if (o.value === batPage) return batPage
                return root.batPageOptions.length ? root.batPageOptions[0].value : "overview"
            }
            onConfirmChanged: if (confirm !== "") confirmTimer.restart()
            Timer {
                id: confirmTimer
                interval: 5000
                onTriggered: pop.confirm = ""
            }
            Component.onCompleted: root.refreshTlp()

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

                        // ======================================== CPU =====
                        Column {
                            visible: pop.activeTab === "cpu" && root.cpu != null
                            width: parent.width
                            spacing: Theme.spacingL

                            HeroCard {
                                visible: root.cpu != null && root.cpu.hasFreq === true && root.cores.length > 0
                                width: parent.width
                                icon: root.metricIcon("cpu")
                                title: "Frequency"
                                value: root.fmtFreq(root.panelFreq(), false)
                                caption: root.modeLabel()
                                progress: root.freqFraction(root.panelFreq())
                            }

                            SectionCard {
                                visible: root.opt("cpuShowPerformance", true)
                                         || root.opt("freqShowMin", true) || root.opt("freqShowMax", true)
                                width: parent.width
                                title: "Performance"
                                icon: "tune"
                                bodySpacing: Theme.spacingS

                                SwitchRow {
                                    visible: root.opt("cpuShowPerformance", true)
                                             && root.cpu != null && root.cpu.turboSupported === true
                                    width: parent.width
                                    icon: "bolt"
                                    label: "Turbo boost"
                                    checked: root.cpu != null && root.cpu.turbo === true
                                    onToggled: value => root.setTurbo(value)
                                }

                                // frequency limits: titled group right under turbo
                                Column {
                                    visible: root.cpu != null && root.cpu.hwMax > root.cpu.hwMin
                                             && (root.opt("freqShowMin", true) || root.opt("freqShowMax", true))
                                    width: parent.width
                                    spacing: Theme.spacingXS

                                    FieldLabel {
                                        text: "Frequency limits"
                                        icon: "swap_vert"
                                    }
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
                                    visible: root.opt("cpuShowPerformance", true)
                                    width: parent.width
                                    spacing: Theme.spacingXS

                                    FieldLabel {
                                        text: "Profile"
                                        icon: "tune"
                                    }
                                    SegmentedControl {
                                        width: parent.width
                                        options: root.profileOptions
                                        current: root.activeProfile()
                                        onSelected: value => root.applyPreset(value)
                                    }
                                }

                                Column {
                                    visible: root.opt("cpuShowPerformance", true) && root.governorOptions.length > 0
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
                                    visible: root.opt("cpuShowPerformance", true) && root.eppOptions.length > 0
                                    width: parent.width
                                    spacing: Theme.spacingXS

                                    FieldLabel { text: "Energy preference"; icon: "battery_charging_full" }
                                    SegmentedControl {
                                        width: parent.width
                                        maxPerRow: 4      // five options -> 3 + 2, wide enough for icons
                                        options: root.eppOptions
                                        current: root.cpu ? root.cpu.epp : ""
                                        onSelected: value => root.setEpp(value)
                                    }
                                }
                            }

                            SectionCard {
                                visible: root.cores.length > 0 && root.opt("freqCores", true)
                                width: parent.width
                                title: "Per-core frequency"
                                icon: root.metricIcon("cpu")

                                Grid {
                                    id: freqGrid
                                    width: parent.width
                                    columns: root.freqColumns
                                    columnSpacing: Theme.spacingM
                                    rowSpacing: Theme.spacingXS

                                    Repeater {
                                        model: root.cores.length
                                        delegate: StatRow {
                                            width: (freqGrid.width - (root.freqColumns - 1) * Theme.spacingM) / root.freqColumns
                                            label: "C" + root.coreId(index)
                                            value: root.fmtFreq(root.coreFreq(index), false)
                                            progress: root.freqFraction(root.coreFreq(index))
                                        }
                                    }
                                }
                            }

                            HeroCard {
                                visible: root.cpu != null && (root.pkgTemp() !== null || root.tempCoreList().length > 0)
                                width: parent.width
                                icon: root.metricIcon("cpu")
                                title: "Temperature"
                                value: root.fmtTemp(root.pkgTemp(), false)
                                caption: "CPU package"
                                         + (root.cpu && root.cpu.physicalCores > 0
                                            ? " · " + root.cpu.physicalCores + " cores, " + root.cpu.threads + " threads"
                                            : "")
                                progress: root.pkgTemp() === null ? -1 : root.clamp100(root.pkgTemp() / 1000)
                            }

                            SectionCard {
                                visible: root.tempCoreList().length > 0 && root.opt("tempCores", true)
                                width: parent.width
                                title: "Physical cores"
                                icon: root.metricIcon("cpu")

                                Grid {
                                    id: tempGrid
                                    width: parent.width
                                    columns: root.tempColumns
                                    columnSpacing: Theme.spacingM
                                    rowSpacing: Theme.spacingXS

                                    Repeater {
                                        model: root.tempCoreList().length
                                        delegate: StatRow {
                                            width: (tempGrid.width - (root.tempColumns - 1) * Theme.spacingM) / root.tempColumns
                                            icon: "thermostat"
                                            label: "Core " + (root.tempCoreList()[index] ? root.tempCoreList()[index].id : index)
                                            value: root.tempCoreList()[index] ? root.fmtTemp(root.tempCoreList()[index].mc, false) : "–"
                                            progress: root.tempCoreList()[index] ? root.clamp100(root.tempCoreList()[index].mc / 1000) : -1
                                        }
                                    }
                                }
                            }

                            HeroCard {
                                width: parent.width
                                icon: root.metricIcon("cpu")
                                title: "Usage"
                                value: Math.round(root.usageAll) + "%"
                                caption: root.cpu && root.cpu.threads > 0 ? root.cpu.threads + " threads" : "CPU usage"
                                progress: root.usageAll
                            }

                            SectionCard {
                                visible: root.cores.length > 0 && root.opt("usageCores", true)
                                width: parent.width
                                title: "Per-core usage"
                                icon: root.metricIcon("cpu")

                                Grid {
                                    id: usageGrid
                                    width: parent.width
                                    columns: root.usageColumns
                                    columnSpacing: Theme.spacingM
                                    rowSpacing: Theme.spacingXS

                                    Repeater {
                                        model: root.cores.length
                                        delegate: StatRow {
                                            width: (usageGrid.width - (root.usageColumns - 1) * Theme.spacingM) / root.usageColumns
                                            label: "C" + root.coreId(index)
                                            value: Math.round(root.coreUsage(index)) + "%"
                                            progress: root.coreUsage(index)
                                        }
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

                        // ======================================= RAM =====
                        Column {
                            visible: pop.activeTab === "mem" && root.mem != null
                            width: parent.width
                            spacing: Theme.spacingL

                            HeroCard {
                                width: parent.width
                                icon: "developer_board"
                                title: "Memory"
                                value: root.fmtBytes(root.memUsedB(), root.opt("memScale", "auto"), true)
                                caption: "of " + root.fmtBytes(root.memTotalB(), root.opt("memScale", "auto"), true) + " used"
                                progress: root.memPct()
                            }

                            SectionCard {
                                width: parent.width
                                title: "Memory"
                                icon: "memory"

                                StatRow {
                                    width: parent.width
                                    icon: "memory"
                                    label: "Used"
                                    value: root.fmtBytes(root.memUsedB(), root.opt("memScale", "auto"), true)
                                    progress: root.memPct()
                                }
                                StatRow {
                                    width: parent.width
                                    icon: "check_circle"
                                    label: "Available"
                                    value: root.fmtBytes(root.memKB(root.mem ? root.mem.avail : 0), root.opt("memScale", "auto"), true)
                                }
                                StatRow {
                                    visible: root.mem != null && root.mem.free != null
                                    width: parent.width
                                    icon: "cloud"
                                    label: "Free"
                                    value: root.fmtBytes(root.memKB(root.mem ? root.mem.free : 0), root.opt("memScale", "auto"), true)
                                }
                                StatRow {
                                    visible: root.mem != null && root.mem.cached != null
                                    width: parent.width
                                    icon: "cached"
                                    label: "Cached"
                                    value: root.fmtBytes(root.memCachedKB() * 1024, root.opt("memScale", "auto"), true)
                                }
                                StatRow {
                                    visible: root.mem != null && root.mem.buffers > 0
                                    width: parent.width
                                    icon: "inventory_2"
                                    label: "Buffers"
                                    value: root.fmtBytes(root.memKB(root.mem ? root.mem.buffers : 0), root.opt("memScale", "auto"), true)
                                }
                                StatRow {
                                    visible: root.mem != null && root.mem.shared > 0
                                    width: parent.width
                                    icon: "share"
                                    label: "Shared"
                                    value: root.fmtBytes(root.memKB(root.mem ? root.mem.shared : 0), root.opt("memScale", "auto"), true)
                                }
                                StatRow {
                                    width: parent.width
                                    icon: "developer_board"
                                    label: "Total"
                                    value: root.fmtBytes(root.memTotalB(), root.opt("memScale", "auto"), true)
                                }
                            }

                            SectionCard {
                                visible: root.mem != null && (root.mem.swapTotal > 0 || root.mem.zramTotal > 0)
                                width: parent.width
                                title: "Swap & compression"
                                icon: "swap_horiz"

                                StatRow {
                                    visible: root.mem != null && root.mem.swapTotal > 0
                                    width: parent.width
                                    icon: "swap_horiz"
                                    label: "Swap"
                                    value: root.mem ? root.fmtBytesPair((root.mem.swapTotal - root.mem.swapFree) * 1024, root.mem.swapTotal * 1024, root.opt("memScale", "auto"), true) : ""
                                    progress: root.mem && root.mem.swapTotal > 0 ? 100 * (root.mem.swapTotal - root.mem.swapFree) / root.mem.swapTotal : -1
                                }
                                StatRow {
                                    visible: root.mem != null && root.mem.zramTotal > 0
                                    width: parent.width
                                    icon: "compress"
                                    label: "ZRAM"
                                    value: root.mem ? root.fmtBytesPair(root.memKB(root.mem.zramUsed), root.memKB(root.mem.zramTotal), root.opt("memScale", "auto"), true) : ""
                                    progress: root.mem && root.mem.zramTotal > 0 ? 100 * root.mem.zramUsed / root.mem.zramTotal : -1
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
                                    readonly property var procs: (g && g.procs) ? g.procs : []

                                    width: pages.width
                                    spacing: Theme.spacingL

                                    HeroCard {
                                        width: parent.width
                                        icon: "auto_awesome_mosaic"
                                        title: "GPU" + (root.gpus.length > 1 ? " " + (index + 1) : "")
                                        value: gpuCol.g ? gpuCol.g.name : ""
                                        caption: gpuCol.g ? (root.gpuAsleep(gpuCol.g)
                                                 ? gpuCol.g.driver + " · powered down (not woken to read stats)"
                                                 : gpuCol.g.driver
                                                   + (gpuCol.g.driverVersion ? " " + gpuCol.g.driverVersion : "")) : ""
                                        progress: gpuCol.g && gpuCol.g.usage != null ? gpuCol.g.usage : -1
                                    }

                                    SectionCard {
                                        visible: gpuCol.g != null && root.gpuShow("Util")
                                                 && (gpuCol.g.usage != null || gpuCol.g.usageMem != null
                                                     || gpuCol.g.usageEnc != null || gpuCol.g.usageDec != null)
                                        width: parent.width
                                        title: "Utilization"
                                        icon: "show_chart"

                                        StatRow {
                                            visible: gpuCol.g != null && gpuCol.g.usage != null
                                            width: parent.width
                                            icon: "show_chart"
                                            label: "GPU"
                                            value: gpuCol.g ? gpuCol.g.usage + "%" : ""
                                            progress: gpuCol.g ? gpuCol.g.usage : -1
                                        }
                                        StatRow {
                                            visible: gpuCol.g != null && gpuCol.g.usageMem != null
                                            width: parent.width
                                            icon: "memory"
                                            label: "Memory controller"
                                            value: gpuCol.g ? gpuCol.g.usageMem + "%" : ""
                                            progress: gpuCol.g ? gpuCol.g.usageMem : -1
                                        }
                                        StatRow {
                                            visible: gpuCol.g != null && gpuCol.g.usageEnc != null
                                            width: parent.width
                                            icon: "videocam"
                                            label: "Encoder"
                                            value: gpuCol.g ? gpuCol.g.usageEnc + "%" : ""
                                        }
                                        StatRow {
                                            visible: gpuCol.g != null && gpuCol.g.usageDec != null
                                            width: parent.width
                                            icon: "movie"
                                            label: "Decoder"
                                            value: gpuCol.g ? gpuCol.g.usageDec + "%" : ""
                                        }
                                    }

                                    SectionCard {
                                        visible: gpuCol.g != null && root.gpuShow("Mem")
                                                 && gpuCol.g.vramTotal != null && gpuCol.g.vramTotal > 0
                                        width: parent.width
                                        title: "Memory"
                                        icon: "developer_board"

                                        StatRow {
                                            width: parent.width
                                            icon: "developer_board"
                                            label: "VRAM"
                                            value: gpuCol.g ? root.fmtBytesPair(gpuCol.g.vramUsed, gpuCol.g.vramTotal, "auto", true) : ""
                                            progress: gpuCol.g ? root.gpuVramPct(gpuCol.g) : -1
                                        }
                                        StatRow {
                                            visible: gpuCol.g != null && gpuCol.g.vramFree != null
                                            width: parent.width
                                            icon: "cloud"
                                            label: "VRAM free"
                                            value: gpuCol.g ? root.fmtBytes(gpuCol.g.vramFree, "auto", true) : ""
                                        }
                                        StatRow {
                                            visible: gpuCol.g != null && gpuCol.g.vramReserved != null && gpuCol.g.vramReserved > 0
                                            width: parent.width
                                            icon: "lock"
                                            label: "VRAM reserved"
                                            value: gpuCol.g ? root.fmtBytes(gpuCol.g.vramReserved, "auto", true) : ""
                                        }
                                    }

                                    SectionCard {
                                        visible: gpuCol.g != null && root.gpuShow("Thermals")
                                                 && !!(gpuCol.g.temp != null || gpuCol.g.tempMem != null
                                                      || gpuCol.g.tempLimit != null || gpuCol.g.fanRpm != null
                                                      || gpuCol.g.fanPct != null || gpuCol.g.throttle)
                                        width: parent.width
                                        title: "Thermals"
                                        icon: "thermostat"

                                        StatRow {
                                            visible: gpuCol.g != null && gpuCol.g.temp != null
                                            width: parent.width
                                            icon: "thermostat"
                                            label: "GPU"
                                            value: gpuCol.g ? root.fmtTemp(gpuCol.g.temp, false) : ""
                                            progress: gpuCol.g ? root.clamp100(gpuCol.g.temp / 1000) : -1
                                        }
                                        StatRow {
                                            visible: gpuCol.g != null && gpuCol.g.tempMem != null
                                            width: parent.width
                                            icon: "thermostat"
                                            label: "Memory"
                                            value: gpuCol.g ? root.fmtTemp(gpuCol.g.tempMem, false) : ""
                                        }
                                        StatRow {
                                            visible: gpuCol.g != null && gpuCol.g.tempLimit != null
                                            width: parent.width
                                            icon: "dangerous"
                                            label: "Shutdown limit"
                                            value: gpuCol.g ? root.fmtTemp(gpuCol.g.tempLimit, false) : ""
                                        }
                                        StatRow {
                                            visible: gpuCol.g != null && (gpuCol.g.fanRpm != null || gpuCol.g.fanPct != null)
                                            width: parent.width
                                            icon: "mode_fan"
                                            label: "Fan"
                                            value: !gpuCol.g ? "" : ((gpuCol.g.fanRpm != null ? gpuCol.g.fanRpm + " RPM" : "")
                                                   + (gpuCol.g.fanRpm != null && gpuCol.g.fanPct != null ? "  " : "")
                                                   + (gpuCol.g.fanPct != null ? gpuCol.g.fanPct + "%" : ""))
                                        }
                                        StatRow {
                                            visible: gpuCol.g != null && !!gpuCol.g.throttle
                                            width: parent.width
                                            icon: "slow_motion_video"
                                            label: "Clock limiters"
                                            value: root.gpuThrottle(gpuCol.g)
                                        }
                                    }

                                    SectionCard {
                                        visible: gpuCol.g != null && root.gpuShow("Power")
                                                 && (gpuCol.g.powerW != null || root.gpuPowerLimits(gpuCol.g) !== "")
                                        width: parent.width
                                        title: "Power"
                                        icon: "bolt"

                                        StatRow {
                                            visible: gpuCol.g != null && gpuCol.g.powerW != null
                                            width: parent.width
                                            icon: "bolt"
                                            label: "Draw"
                                            value: root.gpuPowerText(gpuCol.g)
                                        }
                                        StatRow {
                                            visible: gpuCol.g != null && root.gpuPowerLimits(gpuCol.g) !== ""
                                            width: parent.width
                                            icon: "tune"
                                            label: "Limits"
                                            value: root.gpuPowerLimits(gpuCol.g)
                                        }
                                    }

                                    SectionCard {
                                        visible: gpuCol.g != null && root.gpuShow("Clocks")
                                                 && !!(gpuCol.g.freq != null || gpuCol.g.freqMem != null
                                                      || gpuCol.g.freqSm != null || gpuCol.g.freqVideo != null
                                                      || gpuCol.g.pstate)
                                        width: parent.width
                                        title: "Clocks"
                                        icon: "speed"

                                        StatRow {
                                            visible: gpuCol.g != null && gpuCol.g.freq != null
                                            width: parent.width
                                            icon: "speed"
                                            label: "Graphics"
                                            value: gpuCol.g ? root.fmtMhz(gpuCol.g.freq, gpuCol.g.freqMax) : ""
                                        }
                                        StatRow {
                                            visible: gpuCol.g != null && gpuCol.g.freqMem != null
                                            width: parent.width
                                            icon: "memory"
                                            label: "Memory"
                                            value: gpuCol.g ? root.fmtMhz(gpuCol.g.freqMem, gpuCol.g.freqMaxMem) : ""
                                        }
                                        StatRow {
                                            visible: gpuCol.g != null && gpuCol.g.freqSm != null
                                            width: parent.width
                                            icon: "developer_board"
                                            label: "SM"
                                            value: gpuCol.g ? root.fmtMhz(gpuCol.g.freqSm, gpuCol.g.freqMaxSm) : ""
                                        }
                                        StatRow {
                                            visible: gpuCol.g != null && gpuCol.g.freqVideo != null
                                            width: parent.width
                                            icon: "movie"
                                            label: "Video"
                                            value: gpuCol.g ? root.fmtMhz(gpuCol.g.freqVideo, null) : ""
                                        }
                                        StatRow {
                                            visible: gpuCol.g != null && !!gpuCol.g.pstate
                                            width: parent.width
                                            icon: "bolt"
                                            label: "Performance state"
                                            value: gpuCol.g ? gpuCol.g.pstate : ""
                                        }
                                    }

                                    SectionCard {
                                        visible: gpuCol.g != null && root.gpuShow("Bus")
                                                 && !!(gpuCol.g.pcieGen != null || gpuCol.g.vbios
                                                      || gpuCol.g.persistence || gpuCol.g.computeMode
                                                      || gpuCol.g.uuid || gpuCol.g.serial)
                                        width: parent.width
                                        title: "Bus & driver"
                                        icon: "cable"

                                        StatRow {
                                            visible: gpuCol.g != null && gpuCol.g.pcieGen != null
                                            width: parent.width
                                            icon: "cable"
                                            label: "PCIe link"
                                            value: root.gpuPcieText(gpuCol.g)
                                        }
                                        StatRow {
                                            visible: gpuCol.g != null && !!gpuCol.g.vbios
                                            width: parent.width
                                            icon: "memory"
                                            label: "VBIOS"
                                            value: gpuCol.g ? gpuCol.g.vbios : ""
                                        }
                                        StatRow {
                                            visible: gpuCol.g != null && !!gpuCol.g.persistence
                                            width: parent.width
                                            icon: "keep"
                                            label: "Persistence mode"
                                            value: gpuCol.g ? gpuCol.g.persistence : ""
                                        }
                                        StatRow {
                                            visible: gpuCol.g != null && !!(gpuCol.g.displayActive || gpuCol.g.displayAttached)
                                            width: parent.width
                                            icon: "monitor"
                                            label: "Display"
                                            value: !gpuCol.g ? "" : ("active: " + (gpuCol.g.displayActive || "–")
                                                   + " · attached: " + (gpuCol.g.displayAttached || "–"))
                                        }
                                        StatRow {
                                            visible: gpuCol.g != null && !!gpuCol.g.computeMode
                                            width: parent.width
                                            icon: "settings"
                                            label: "Compute mode"
                                            value: gpuCol.g ? gpuCol.g.computeMode : ""
                                        }
                                        StatRow {
                                            visible: gpuCol.g != null && !!gpuCol.g.uuid
                                            width: parent.width
                                            icon: "fingerprint"
                                            label: "UUID"
                                            value: gpuCol.g ? gpuCol.g.uuid : ""
                                        }
                                        StatRow {
                                            visible: gpuCol.g != null && !!gpuCol.g.serial
                                            width: parent.width
                                            icon: "tag"
                                            label: "Serial"
                                            value: gpuCol.g ? gpuCol.g.serial : ""
                                        }
                                    }

                                    SectionCard {
                                        visible: gpuCol.g != null && root.gpuShow("Procs") && gpuCol.procs.length > 0
                                        width: parent.width
                                        title: "Processes"
                                        icon: "list"

                                        Repeater {
                                            model: gpuCol.procs.length
                                            delegate: StatRow {
                                                readonly property var p: gpuCol.procs[index] ? gpuCol.procs[index] : null
                                                width: parent.width
                                                icon: "apps"
                                                label: p ? (p.name + " (" + p.pid + ")") : ""
                                                value: p && p.mem != null ? root.fmtBytes(p.mem, "auto", true) : ""
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // ====================================== fans =====
                        Column {
                            visible: pop.activeTab === "fans" && root.fans.length > 0
                            width: parent.width
                            spacing: Theme.spacingL

                            HeroCard {
                                width: parent.width
                                icon: "mode_fan"
                                title: "Fans"
                                value: root.fanRpm() === null ? "–" : Math.round(root.fanRpm()) + " RPM"
                                caption: root.opt("fansDisplay", "max") === "avg" ? "Average fan speed" : "Fastest fan"
                            }

                            SectionCard {
                                width: parent.width
                                title: "Fans"
                                icon: "mode_fan"

                                Repeater {
                                    model: root.fans.length
                                    delegate: StatRow {
                                        width: parent.width
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
                            spacing: Theme.spacingL

                            HeroCard {
                                width: parent.width
                                icon: "storage"
                                title: "Disk"
                                value: root.diskSel() ? Math.round(root.diskPct(root.diskSel())) + "% used" : "–"
                                caption: root.diskSel()
                                         ? root.diskSel().mount + " · "
                                           + root.fmtBytesPair(root.diskSel().used, root.diskSel().used + root.diskSel().avail, root.opt("diskScale", "auto"), true)
                                         : ""
                                progress: root.diskSel() ? root.diskPct(root.diskSel()) : -1
                            }

                            SectionCard {
                                width: parent.width
                                title: "Filesystems"
                                icon: "storage"

                                Repeater {
                                    model: root.disks.length
                                    delegate: StatRow {
                                        readonly property var d: root.disks[index] ? root.disks[index] : null
                                        width: parent.width
                                        icon: "storage"
                                        label: d ? d.mount : ""
                                        value: d ? root.fmtBytesPair(d.used, d.used + d.avail, root.opt("diskScale", "auto"), true) : ""
                                        progress: d ? root.diskPct(d) : -1
                                    }
                                }
                            }
                        }

                        // ==================================== battery ====
                        Column {
                            visible: pop.activeTab === "bat" && root.bats.length > 0
                            width: parent.width
                            spacing: Theme.spacingL

                            HeroCard {
                                width: parent.width
                                icon: root.batIcon()
                                title: "Battery"
                                value: Math.round(root.batPct()) + "%"
                                caption: root.batCaption()
                                progress: root.batPct()
                            }

                            SegmentedControl {
                                visible: root.batPageOptions.length > 1
                                width: parent.width
                                options: root.batPageOptions
                                current: pop.batPageActive
                                onSelected: value => pop.batPage = value
                            }

                            // ------------------------------------ overview ----
                            Column {
                                visible: pop.batPageActive === "overview"
                                width: parent.width
                                spacing: Theme.spacingL

                                SectionCard {
                                    width: parent.width
                                    title: "Power"
                                    icon: "power"

                                    StatRow {
                                        width: parent.width
                                        icon: root.onAc ? "power" : "battery_full"
                                        label: "Power source"
                                        value: root.snap && root.snap.ac === null ? "Unknown" : (root.onAc ? "AC adapter" : "Battery")
                                    }

                                    Column {
                                        visible: root.tlpInstalled && root.tlpInfo.profiles === true
                                        width: parent.width
                                        spacing: Theme.spacingXS

                                        FieldLabel { text: "TLP profile"; icon: "tune" }
                                        SegmentedControl {
                                            width: parent.width
                                            options: [
                                                { label: "Power saver", value: "power-saver", icon: "eco" },
                                                { label: "Balanced", value: "balanced", icon: "balance" },
                                                { label: "Performance", value: "performance", icon: "rocket_launch" }
                                            ]
                                            current: root.tlpInfo ? root.tlpInfo.profile : ""
                                            onSelected: value => root.setTlpProfile(value)
                                        }
                                    }

                                    Column {
                                        visible: root.tlpInstalled && root.tlpInfo.profiles !== true
                                        width: parent.width
                                        spacing: Theme.spacingXS

                                        FieldLabel { text: "TLP mode"; icon: "tune" }
                                        SegmentedControl {
                                            width: parent.width
                                            options: [
                                                { label: "Auto", value: "auto", icon: "autorenew" },
                                                { label: "AC", value: "ac", icon: "power" },
                                                { label: "Battery", value: "bat", icon: "battery_full" }
                                            ]
                                            current: !root.tlpInfo ? "" : (root.tlpInfo.manual ? root.tlpInfo.mode : "auto")
                                            onSelected: value => root.setTlpMode(value)
                                        }
                                    }

                                    StatRow {
                                        visible: root.tlpInstalled
                                        width: parent.width
                                        icon: "info"
                                        label: "TLP"
                                        value: root.tlpInstalled && root.tlpInfo.version !== "" ? "Version " + root.tlpInfo.version : "Installed"
                                    }
                                }

                                Callout {
                                    visible: root.tlpInfo !== null && !root.tlpInstalled
                                    width: parent.width
                                    tone: "info"
                                    text: "TLP is not installed. Charge limits still work through the kernel, but power profiles and settings that survive a reboot need TLP (linrunner.de/tlp)."
                                }

                                Repeater {
                                    model: root.opt("batShowHealth", true) ? root.bats.length : 0

                                    delegate: SectionCard {
                                        id: hc
                                        readonly property var b: root.bats[index] ? root.bats[index] : null
                                        width: parent.width
                                        title: "Battery health" + root.batName(index)
                                        icon: "health_and_safety"

                                        StatRow {
                                            visible: hc.b !== null && root.batHealth(hc.b) >= 0
                                            width: parent.width
                                            icon: "health_and_safety"
                                            label: "Health"
                                            value: Math.round(root.batHealth(hc.b)) + "%"
                                            progress: root.batHealth(hc.b)
                                        }
                                        StatRow {
                                            visible: hc.b !== null && hc.b.energyFull != null
                                            width: parent.width
                                            icon: "battery_full"
                                            label: "Capacity"
                                            value: hc.b ? root.fmtWh(hc.b.energyFull)
                                                   + (hc.b.energyDesign != null ? " of " + root.fmtWh(hc.b.energyDesign) : "") : ""
                                        }
                                        StatRow {
                                            visible: hc.b !== null && hc.b.energyNow != null
                                            width: parent.width
                                            icon: "battery_charging_full"
                                            label: "Charge"
                                            value: hc.b ? root.fmtWh(hc.b.energyNow) : ""
                                        }
                                        StatRow {
                                            visible: hc.b !== null && hc.b.powerNow != null
                                            width: parent.width
                                            icon: "bolt"
                                            label: hc.b && hc.b.status === "Charging" ? "Charging power" : "Power draw"
                                            value: hc.b ? root.fmtW(hc.b.powerNow) : ""
                                        }
                                        StatRow {
                                            visible: hc.b !== null && hc.b.voltage != null
                                            width: parent.width
                                            icon: "electric_bolt"
                                            label: "Voltage"
                                            value: hc.b ? root.fmtV(hc.b.voltage) : ""
                                        }
                                        StatRow {
                                            visible: hc.b !== null && hc.b.cycles != null
                                            width: parent.width
                                            icon: "autorenew"
                                            label: "Charge cycles"
                                            value: hc.b ? String(hc.b.cycles) : ""
                                        }
                                        StatRow {
                                            visible: hc.b !== null && hc.b.temp != null
                                            width: parent.width
                                            icon: "thermostat"
                                            label: "Temperature"
                                            value: hc.b && hc.b.temp != null
                                                   ? root.fmtTemp(hc.b.temp * 100, false) : ""
                                        }
                                        StatRow {
                                            visible: hc.b !== null && hc.b.tech !== ""
                                            width: parent.width
                                            icon: "science"
                                            label: "Chemistry"
                                            value: hc.b ? hc.b.tech : ""
                                        }
                                        StatRow {
                                            visible: hc.b !== null && (hc.b.manufacturer !== "" || hc.b.model !== "")
                                            width: parent.width
                                            icon: "factory"
                                            label: "Model"
                                            value: hc.b
                                                   ? (hc.b.manufacturer + " " + hc.b.model).trim() : ""
                                        }
                                    }
                                }
                            }

                            // ------------------------------------ charging ----
                            Column {
                                visible: pop.batPageActive === "charging"
                                width: parent.width
                                spacing: Theme.spacingL

                                Repeater {
                                    model: root.bats.length

                                    delegate: Column {
                                        id: chg
                                        readonly property var b: root.bats[index] ? root.bats[index] : null
                                        width: parent.width
                                        spacing: Theme.spacingL

                                        SectionCard {
                                            visible: chg.b !== null && chg.b.hasStop === true
                                            width: parent.width
                                            title: "Charge limit" + root.batName(index)
                                            icon: "battery_saver"
                                            caption: root.chargeCaption(chg.b)

                                            Column {
                                                width: parent.width
                                                spacing: Theme.spacingXS

                                                FieldLabel { text: "Preset"; icon: "tune" }
                                                SegmentedControl {
                                                    width: parent.width
                                                    options: root.chargePresets
                                                    current: root.chargePreset(chg.b)
                                                    onSelected: value => root.applyChargePreset(chg.b, value)
                                                }
                                            }

                                            SliderRow {
                                                id: startRow
                                                visible: chg.b !== null && chg.b.hasStart === true
                                                width: parent.width
                                                icon: "play_arrow"
                                                label: "Start charging below"
                                                valueText: Math.round(startRow.shown) + "%"
                                                from: root.tlpRange("startMin", 0)
                                                to: root.tlpRange("startMax", 99)
                                                step: 1
                                                value: chg.b && chg.b.start != null ? chg.b.start : 0
                                                onReleased: newValue => root.setChargeStart(chg.b, newValue)
                                            }

                                            SliderRow {
                                                id: stopRow
                                                width: parent.width
                                                icon: "stop"
                                                label: "Stop charging at"
                                                valueText: Math.round(stopRow.shown) + "%"
                                                from: Math.max(root.tlpRange("stopMin", 1), 20)
                                                to: root.tlpRange("stopMax", 100)
                                                step: 1
                                                value: chg.b && chg.b.stop != null ? chg.b.stop : 100
                                                onReleased: newValue => root.setChargeStop(chg.b, newValue)
                                            }
                                        }

                                        SectionCard {
                                            visible: chg.b !== null && chg.b.hasStop === true
                                            width: parent.width
                                            title: "Charge now" + root.batName(index)
                                            icon: "bolt"
                                            caption: "One-off actions. The configured limit comes back at the next boot or with Restore."

                                            Grid {
                                                id: nowGrid
                                                width: parent.width
                                                columns: 2
                                                columnSpacing: Theme.spacingS
                                                rowSpacing: Theme.spacingS

                                                ActionButton {
                                                    width: (nowGrid.width - nowGrid.columnSpacing) / 2
                                                    icon: "battery_full"
                                                    text: "Charge to full"
                                                    onClicked: root.chargeAction("fullcharge", chg.b.name)
                                                }
                                                ActionButton {
                                                    visible: root.tlpInstalled && chg.b !== null && chg.b.hasStart === true
                                                    width: (nowGrid.width - nowGrid.columnSpacing) / 2
                                                    icon: "bolt"
                                                    text: "Charge once"
                                                    onClicked: root.chargeAction("chargeonce", chg.b.name)
                                                }
                                                ActionButton {
                                                    visible: root.tlpInstalled
                                                    width: (nowGrid.width - nowGrid.columnSpacing) / 2
                                                    variant: "outlined"
                                                    icon: "restart_alt"
                                                    text: "Restore limits"
                                                    onClicked: root.restoreCharge(chg.b.name)
                                                }
                                            }
                                        }

                                        SectionCard {
                                            visible: chg.b !== null && chg.b.behaviours.length > 1
                                            width: parent.width
                                            title: "Charge behaviour" + root.batName(index)
                                            icon: "swap_vert"
                                            caption: "Kernel-level control: pause charging while on AC, or force the battery to discharge."

                                            SegmentedControl {
                                                width: parent.width
                                                options: root.behaviourOptions
                                                current: chg.b ? chg.b.behaviour : ""
                                                onSelected: value => root.setBehaviour(chg.b.name, value)
                                            }
                                        }

                                        SectionCard {
                                            visible: root.tlpHasFeature("recalibration") && chg.b !== null
                                            width: parent.width
                                            title: "Maintenance" + root.batName(index)
                                            icon: "build"

                                            Callout {
                                                width: parent.width
                                                tone: "warn"
                                                text: "Both actions need the charger connected and fully drain the battery. Discharging takes a while; recalibration also recharges to 100%."
                                            }

                                            Grid {
                                                id: maintGrid
                                                width: parent.width
                                                columns: 2
                                                columnSpacing: Theme.spacingS
                                                rowSpacing: Theme.spacingS

                                                ActionButton {
                                                    readonly property string key: chg.b ? "discharge:" + chg.b.name : ""
                                                    width: (maintGrid.width - maintGrid.columnSpacing) / 2
                                                    icon: "battery_alert"
                                                    variant: pop.confirm === key ? "filled" : "tonal"
                                                    danger: pop.confirm === key
                                                    text: pop.confirm === key ? "Tap to confirm" : "Discharge"
                                                    onClicked: {
                                                        if (pop.confirm === key) { pop.confirm = ""; root.chargeAction("discharge", chg.b.name) }
                                                        else pop.confirm = key
                                                    }
                                                }
                                                ActionButton {
                                                    readonly property string key: chg.b ? "recalibrate:" + chg.b.name : ""
                                                    width: (maintGrid.width - maintGrid.columnSpacing) / 2
                                                    icon: "published_with_changes"
                                                    variant: pop.confirm === key ? "filled" : "tonal"
                                                    danger: pop.confirm === key
                                                    text: pop.confirm === key ? "Tap to confirm" : "Recalibrate"
                                                    onClicked: {
                                                        if (pop.confirm === key) { pop.confirm = ""; root.chargeAction("recalibrate", chg.b.name) }
                                                        else pop.confirm = key
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }

                                Callout {
                                    visible: root.bats.length > 0 && !root.bats.some(b => b.hasStop === true)
                                    width: parent.width
                                    tone: "info"
                                    text: "This battery does not expose charge thresholds, so there is nothing to limit. Support depends on the laptop vendor and kernel version."
                                }
                            }

                            // ------------------------------------- tuning ----
                            Column {
                                visible: pop.batPageActive === "tuning"
                                width: parent.width
                                spacing: Theme.spacingL

                                Callout {
                                    visible: !root.tlpInstalled
                                    width: parent.width
                                    tone: "info"
                                    text: "Tuning edits TLP parameters, so it needs TLP to be installed (linrunner.de/tlp)."
                                }

                                SectionCard {
                                    visible: root.tlpInstalled
                                    width: parent.width
                                    title: "Profile to edit"
                                    icon: "tune"
                                    caption: root.tlpInfo && root.tlpInfo.profiles
                                        ? "Performance is used on AC power, Balanced on battery and Power saver when you pick it."
                                        : "TLP applies the AC set on AC power and the battery set on battery power."

                                    SegmentedControl {
                                        width: parent.width
                                        options: root.tuneProfiles
                                        current: pop.tuneProfile
                                        onSelected: value => pop.tuneProfile = value
                                    }
                                }

                                Repeater {
                                    model: root.tlpInstalled ? root.tlpGroups : []

                                    delegate: SectionCard {
                                        id: grp
                                        readonly property var group: modelData
                                        readonly property var items: root.tlpItems(modelData, pop.tuneProfile)
                                        visible: items.length > 0
                                        width: parent.width
                                        title: modelData.title
                                        icon: modelData.icon

                                        Repeater {
                                            model: grp.items

                                            delegate: TlpField {
                                                readonly property string k: root.tlpKey(modelData, pop.tuneProfile)
                                                width: parent.width
                                                icon: modelData.icon
                                                label: modelData.label
                                                type: modelData.type
                                                options: root.tlpOptions(modelData)
                                                yesValue: modelData.onValue !== undefined ? modelData.onValue : "1"
                                                noValue: modelData.offValue !== undefined ? modelData.offValue : "0"
                                                from: modelData.min !== undefined ? modelData.min : 0
                                                to: modelData.max !== undefined ? modelData.max : 100
                                                def: modelData.def !== undefined ? modelData.def : 0
                                                unit: modelData.unit !== undefined ? modelData.unit : ""
                                                value: root.tlpValue(k)
                                                managed: root.tlpManaged(k)
                                                source: root.tlpSource(k)
                                                onCommit: newValue => root.tlpSet(k, newValue, modelData.label)
                                                onReset: root.tlpReset([k])
                                            }
                                        }
                                    }
                                }

                                SectionCard {
                                    visible: root.tlpInstalled
                                    width: parent.width
                                    title: "Where changes go"
                                    icon: "description"
                                    caption: "Changes are written to " + (root.tlpInfo ? root.tlpInfo.dropin : "/etc/tlp.d/99-dms-cpufreq.conf")
                                             + " and applied with tlp start, which also returns TLP to automatic mode. "
                                             + "/etc/tlp.conf is read last and wins over this file."

                                    ActionButton {
                                        visible: root.tlpInfo !== null && root.tlpInfo.managed.length > 0
                                        width: parent.width
                                        variant: pop.confirm === "resetall" ? "filled" : "outlined"
                                        danger: pop.confirm === "resetall"
                                        icon: "restart_alt"
                                        text: pop.confirm === "resetall" ? "Tap again to reset everything" : "Reset all plugin settings"
                                        onClicked: {
                                            if (pop.confirm === "resetall") { pop.confirm = ""; root.tlpReset([]) }
                                            else pop.confirm = "resetall"
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
}
