# dms-cpufreq (System Monitor)

> [!WARNING]
> **Disclaimer:** This project was "vibe coded" primarily for personal use that I decided to open-source. It is provided as-is, without any warranties.
>
> **USE AT YOUR OWN RISK**

CPU frequency control and system monitoring for DankMaterialShell (DMS), modelled on
[cosmic-cpufreq](https://github.com/MAHcodes/cosmic-cpufreq) and extended with RAM, GPU, fans and disk.

## What you get

Seven metrics, each with its own **popout tab** and its own **settings tab**:

| Metric | Popout tab | Per-metric settings |
|---|---|---|
| Frequency | turbo, profile, governor, energy preference, min/max limits, per-core grid | bar value (avg/min/max), unit GHz/MHz, decimals, show/hide min limit, show/hide max limit, per-core grid |
| Temperature | package + per-core temperatures | unit C/F |
| CPU usage | total + per-core | |
| RAM | used / available / total / swap | bar value (percent, used, used/total), unit |
| GPU | usage, VRAM, temp, fan, clock, power (AMD, Intel, NVIDIA) | bar value (usage, temp, VRAM), which GPU |
| Fans | every fan reported by hwmon | bar value (fastest or average) |
| Disk | every mounted filesystem | bar value (percent, used, free, used/total), unit, mount point |

Every metric also has: **show in bar**, **show tab in popout**, **show icon in bar**, **show unit in bar**.
Only frequency is shown in the bar by default. Metrics your hardware does not report are hidden automatically.

Bar entries are separated by two spaces.

## Install

```
bash install.sh           # no password prompts when changing CPU settings (default)
bash install.sh --auth    # ask for admin authentication instead
```

This puts the helper at `/usr/local/bin/dms-cpufreqctl`, the polkit policy at
`/usr/share/polkit-1/actions/dev.dms.cpufreq.policy` (via `sudo`), and symlinks the plugin into
`~/.config/DankMaterialShell/plugins/CpuFreq`. Then: Settings -> Plugins -> Scan for Plugins ->
enable **System Monitor** -> add it to a bar section -> `dms restart`.
While developing, `dms ipc call plugins reload cpuFreq` reloads it.

### Installing from the DMS plugin registry

The registry (or `dms plugins install`) only copies the plugin files. This plugin also needs a small
root helper and a polkit policy that live **outside** the plugin folder, so run the installer once
from the plugin folder:

```
bash ~/.config/DankMaterialShell/plugins/<plugin folder>/install.sh
```

Until the helper is installed the popout shows "Waiting for data" and the bar shows an ellipsis.
Optional: `nvidia-smi` for NVIDIA GPU stats.

## How it works

```
CpuFreq.qml --poll every N s--> dms-cpufreqctl status [sections]   (unprivileged, JSON)
            --on change-------> pkexec dms-cpufreqctl apply ...      (root, via polkit)
```

* `status` only collects the sections you actually use (CPU, RAM, GPU, fans, disk), so e.g.
  `nvidia-smi` is never run unless the GPU metric is enabled.
* **GPU safety:** a GPU in runtime-suspend (typical for hybrid laptops) is reported as "powered
  down" and is never queried, so the plugin does not wake it up and drain battery.
* `apply` is the only privileged part. It validates every argument against what the kernel reports
  (governor / EPP must be in the available lists, frequencies are clamped to hardware limits, turbo
  must be 0/1) and rejects anything else. A profile is a single `apply` call.
* The popout always reflects sysfs, so changes made from a terminal show up on the next poll.

## Passwords

By default the polkit policy lets your **active local session** change CPU settings without a
prompt (`allow_active = yes`); inactive or remote sessions still require admin authentication.
This is not a privilege escalation (the helper only writes cpufreq sysfs, with validated values),
but any program running as you in your session can change your governor, turbo and limits without
asking. Use `bash install.sh --auth` for prompts instead; re-run the installer to switch.

## Design

Components follow Material 3: primary tabs, single-select segmented buttons (selected option in the
accent color, height follows the font size, up to 5 options per row (Energy preference uses 3 + 2 so every option keeps its icon), option icons only when they fit,
inactive options with a subtle tonal fill), 52x32 switches, sliders with a value bubble, linear progress
indicators and tonal cards. Bar text and icons are sized exactly like the built-in DankBar widgets
(`Theme.barTextSize` with the bar's thickness, font scale and "maximize widget text" settings, and
the icon size DMS provides), so they follow your bar settings; the popout uses `fontSizeSmall` /
`fontSizeMedium` / `fontSizeLarge`. Colors only use `Theme`
properties documented for DMS plugins.

## Testing status

* The helper is tested against a fake sysfs tree (all sections, GPU power-state handling, input
  validation, min/max ordering, non-root rejection).
* The QML was loaded and exercised in headless Qt against **stubs** of the DMS modules: every tab
  rendered, settings toggles, real click/drag events produced the expected `apply` arguments, with
  zero QML warnings. It has **not** been run inside a real DMS session, so real `Theme` values,
  the real `PluginSettings` widgets and real Material Symbols icons are unverified. If an icon
  name does not exist in your font it shows as a blank gap; tell me which one.

## Known limitations

* Per-core temperatures need `coretemp` ("Core N" labels). AMD (`k10temp`) exposes a package value only.
* Intel GPUs report clock only (utilisation needs root); NVIDIA needs `nvidia-smi`.
* With several bars or monitors DMS creates one instance per bar and each polls (cheap). Restore on launch can fire once per instance.
* Sliders apply on release, not while dragging.
* NixOS: `install.sh` does not apply; package the helper and policy declaratively.
* The vertical bar shows values without units and stacks entries with spacing instead of two spaces.
