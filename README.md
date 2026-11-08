# dms-cpufreq (System Monitor)

> [!WARNING]
> **Disclaimer:** This project was "vibe coded" primarily for personal use that I decided to open-source. It is provided as-is, without any warranties.
>
> **USE AT YOUR OWN RISK**

CPU frequency control and system monitoring for DankMaterialShell (DMS), modelled on
[cosmic-cpufreq](https://github.com/MAHcodes/cosmic-cpufreq) and extended with RAM, GPU, fans and disk.

## What you get

Eight metrics, each with its own **popout tab** and its own **settings tab**:

| Metric | Popout tab | Per-metric settings |
|---|---|---|
| Frequency | turbo, profile, governor, energy preference, min/max limits, per-core grid | bar values (min/avg/max, any mix), unit GHz/MHz, decimals, show/hide min limit, show/hide max limit, per-core grid columns |
| Temperature | package + per-core temperatures | unit C/F, show/hide per-core, per-core grid columns |
| CPU usage | total + per-core | per-core grid columns |
| RAM | used / available / free / cached / buffers / shared / total / swap / ZRAM | bar values (any mix: percent, used, available, free, used/total), unit |
| GPU | everything the driver exposes: usage (GPU/mem/encoder/decoder), VRAM (used/free/reserved), temps, fan, power draw + limits, graphics/memory/SM/video clocks + max, P-state, PCIe gen/width, VBIOS, driver version, persistence/display/compute mode, UUID/serial, active clock limiters and compute processes (AMD, Intel, NVIDIA) | bar values (any mix: usage, temp, VRAM, power draw, graphics clock), which GPU, toggle each popout section (utilization, memory, thermals, power, clocks, bus & driver, processes) |
| Fans | every fan reported by hwmon | bar value (fastest or average) |
| Disk | every mounted filesystem | bar values (any mix: percent, used, free, used/total), unit, mount point |
| Battery | see [Battery and TLP](#battery-and-tlp) | bar values (any mix: charge, time remaining, power, energy), keep limits across reboots, toggle each popout page (health, charging, tuning) |

Every metric also has: **show in bar**, **show tab in popout**, **show icon in bar**, **show unit in bar**.
Only frequency is shown in the bar by default. Metrics your hardware does not report are hidden automatically.

See [STATS.md](STATS.md) for a guide to every reading: what it means, where it comes from and its quirks.

Per-core temperatures and frequencies use a configurable grid (1-6 columns). Note that CPU
temperature sensors are per **physical** core: a 6-core / 12-thread CPU such as the i7-8750H reports
6 readings (`coretemp`), not 12. The Temp tab says so and shows the core/thread counts.

GPU data comes from sysfs/hwmon, plus a single `nvidia-smi --query-gpu` call on NVIDIA (with a
fallback to the basic field set on older drivers). A runtime-suspended GPU is still never queried.
`nvidia-smi --query-compute-apps` adds the per-GPU compute process list.

Bar entries are separated by two spaces; a dot or line separator is optional (General settings).

## Battery and TLP

The **Battery** tab appears when the machine has a battery and has three pages (each can be hidden in the settings):

* **Overview**: charge, status, time remaining (to empty, or to your charge limit while charging) and power draw in the
  hero card; power source; the **TLP profile** (Power saver / Balanced / Performance on TLP 1.9+, Auto / AC / Battery on
  older versions); per-battery health (capacity vs design, cycles, power, voltage, temperature, chemistry, model).
* **Charging**: per battery, presets (Full 96-100, Balanced 75-80, Lifespan 50-60) plus *start* and *stop* sliders
  (the start slider only shows if the hardware has a start threshold; stop is limited to 20-100 to avoid a limit that never charges);
  *Charge to full*, *Charge once* and *Restore limits*; kernel **charge behaviour** (auto / pause / force discharge, where the kernel
  offers it); ThinkPad **discharge** and **recalibrate** behind a tap-twice confirmation.
* **Tuning**: edit TLP parameters for the profile you pick (Performance = `_AC`, Balanced = `_BAT`, Power saver = `_SAV`, or just
  AC / battery on TLP < 1.9): governor, energy preference, platform profile, turbo, HWP dynamic boost, min/max performance, AMD ABM,
  Radeon DPM, PCIe ASPM, runtime PM, Wi-Fi, audio, SATA link power, AHCI, USB autosuspend, NMI watchdog, Wake-on-LAN and, on TLP 1.10+,
  which profile TLP uses on AC and on battery. Values shown are the ones TLP reports as effective.

How it talks to TLP:

* Read: sysfs (`/sys/class/power_supply`) every poll; `tlp-stat -c/-b/-m`, `tlp --version` and `tlpctl get` every 30 s and when the popout opens.
* TLP profile switch (1.9+): `tlpctl set <profile>` without root when `tlp-pd` runs, otherwise `tlp <profile>` through the helper.
* Charge limits: `tlp setcharge START STOP BAT`. This is **temporary** in TLP, so with *Keep charge limits across reboots* (default on) the
  helper also writes `START/STOP_CHARGE_THRESH_BATx` to `/etc/tlp.d/99-dms-cpufreq.conf`. Without TLP the thresholds are written to sysfs directly (temporary).
* Tuning: the helper validates every key against a whitelist (and every value against its type, range or what the kernel reports),
  writes `/etc/tlp.d/99-dms-cpufreq.conf` atomically and runs `tlp start`, which also leaves TLP's manual mode. *Reset to TLP default*
  removes a key from that file; *Reset all plugin settings* deletes the file.
* TLP reads `/etc/tlp.conf` **last**, so a parameter that is uncommented there wins over the drop-in. The Tuning page shows an
  "Overridden by /etc/tlp.conf" warning on such parameters.
* TLP says to configure a setting for all its profiles, or values from one can spill into another: if you change one of `_AC`/`_BAT`/`_SAV`, check the others.

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
Optional: `nvidia-smi` for NVIDIA GPU stats, TLP for the TLP parts of the Battery tab.

**Upgrading from an older version:** run `install.sh` again, the helper has new commands and the polkit text changed.

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

By default the polkit policy lets your **active local session** change CPU settings, charge limits and the whitelisted TLP
parameters without a prompt (`allow_active = yes`); inactive or remote sessions still require admin authentication.
This is not a privilege escalation (the helper only writes cpufreq/battery sysfs and one TLP drop-in, with validated values),
but any program running as you in your session can change your governor, turbo, charge limit and TLP settings without
asking. Use `bash install.sh --auth` for prompts instead; re-run the installer to switch.

## Design

Components follow Material 3: primary tabs, a primary-container hero card per tab, filled
surface-container cards for each group of rows, single-select segmented buttons (selected option in
the accent color, height follows the font size, up to 5 options per row (Energy preference uses 3 + 2
so every option keeps its icon), option icons only when they fit, inactive options with a subtle
tonal fill), 52x32 switches, sliders with a value bubble, linear progress indicators and tonal
cards. Bar text and icons are sized exactly like the built-in DankBar widgets (`Theme.barTextSize`
with the bar's thickness, font scale and "maximize widget text" settings, and the icon size DMS
provides), so they follow your bar settings; the popout uses `fontSizeSmall` / `fontSizeMedium` /
`fontSizeXXLarge` and elides long values. Colors only use `Theme` properties documented for DMS
plugins.

## Testing status

* The helper is tested against a fake sysfs tree (all sections, GPU power-state handling, input
  validation, min/max ordering, non-root rejection).
* The QML was loaded and exercised in headless Qt against **stubs** of the DMS modules: every tab
  rendered, settings toggles, real click/drag events produced the expected `apply` arguments, with
  zero QML warnings. It has **not** been run inside a real DMS session, so real `Theme` values,
  the real `PluginSettings` widgets and real Material Symbols icons are unverified. If an icon
  name does not exist in your font it shows as a blank gap; tell me which one.

## Known limitations

* Battery: not run against real TLP or a real DMS session. The helper was tested against a fake sysfs tree and fake `tlp`/`tlp-stat`/`tlpctl`
  (status parsing, validation, injection attempts, drop-in writing, sysfs fallback) and the QML in headless Qt against stubs (every page, the
  commands each control issues, error toasts, zero warnings). The `tlp-stat -c` output format differs between TLP versions; the parser
  accepts both the `file Lnnnn: KEY="value"` and the plain `KEY=value` forms and falls back to `/run/tlp/run.conf`.
* Some icons (`battery_*_bar`, `battery_saver`, `published_with_changes`, `monitor_heart`, ...) are unverified in your Material Symbols build; a blank gap means the name is missing.
* `tlp discharge/recalibrate` only exist on ThinkPads; charge-limit support depends on vendor and kernel. Several batteries are combined in the bar.

* Per-core temperatures need `coretemp` ("Core N" labels). AMD (`k10temp`) exposes a package value only.
* Intel GPUs report clock only (utilisation needs root); NVIDIA needs `nvidia-smi`.
* With several bars or monitors DMS creates one instance per bar and each polls (cheap). Restore on launch can fire once per instance.
* Sliders apply on release, not while dragging.
* NixOS: `install.sh` does not apply; package the helper and policy declaratively.
* The vertical bar stacks each entry's unit under its number (smaller font, when *show unit in bar*
  is on) and separates entries with spacing instead of two spaces. The optional separator applies
  in both orientations. Wide `/`-joined numbers (`used/total`) split over lines so they fit.
