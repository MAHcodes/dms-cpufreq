# Stats guide

Every reading the System Monitor plugin shows, what it means, where it comes from, and the
quirks worth knowing. Paths are sysfs/procfs unless a command is named. A value the hardware
or driver does not report shows as "–"; the bar shows "…" until the first poll lands.

## How data is collected

| Source | What | When |
|---|---|---|
| `dms-cpufreqctl status` (this plugin's helper, unprivileged) | sysfs + `/proc` for every enabled metric | every refresh interval (default 2 s) |
| `nvidia-smi --query-gpu` / `--query-compute-apps` | NVIDIA-only details | each poll, only if the GPU metric is on, the card is NVIDIA and awake |
| `tlp-stat -c/-b/-m`, `tlpctl get`, `tlp --version` | TLP config, charge ranges, profile/mode | every 30 s, when the popout opens and after every TLP change |

Only the sections you actually use (bar or popout tab enabled) are collected — e.g. `nvidia-smi`
never runs unless the GPU metric is enabled. A runtime-suspended GPU (hybrid laptops) is reported
as "powered down" and never queried, so reading stats never wakes it.

## Bar entries

One entry per metric with *show in bar* on, separated by two spaces (a dot or line separator is
optional, General settings). Each metric can show several of its values at once — any mix of its
"Bar: …" toggles, joined with spaces (e.g. `45% 65°C` for GPU usage + temperature). In vertical
bars the unit stacks under the number in a smaller font, and `/`-joined numbers (`used/total`,
freq min/avg/max) split over lines (`12.1` over `/16.0`) so they fit. Formatting rules:

* Frequency: any mix of min/avg/max over all logical cores; same-unit values slash-join into
  `0.55/3.42/4.10 GHz` (GHz has configurable decimals, MHz is rounded).
* Temperature: package sensor, °C or °F.
* Usage/RAM/Disk/battery percent: rounded integer with `%`.
* Byte values (RAM, disk, GPU VRAM): one decimal below 100, none above; unit auto-picks TiB/GiB/MiB
  (or a fixed GiB/MiB/GB per setting). Pairs render as `used/total`.
* Battery: any mix of charge %, time to empty/limit as `h:mm`, power draw `12.3 W`, energy `45.6 Wh`.
* GPU: any mix of usage %, temp, VRAM used %, power draw `123.4 W`, graphics clock in MHz.

The battery icon follows charge level and charging state; every other metric has a fixed icon
(toggle with *show icon in bar*).

## Frequency tab

| Stat | Meaning | Source | Notes |
|---|---|---|---|
| Hero: frequency | The avg/min/max (per setting) current clock of all logical cores | `scaling_cur_freq` per CPU, kHz | Progress bar = position between hardware min and max. The caption says which of the three you are seeing. |
| Turbo boost | Whether turbo/boost frequencies are allowed | `intel_pstate/no_turbo` (inverted) or `cpufreq/boost` | On intel_pstate with turbo off, the *effective* max is the base frequency, and the slider max follows it. |
| Profile | Which preset matches live sysfs: saver / balanced / performance, or none (custom) | derived | Presets set governor + EPP + turbo + `min=hw max=hw` in one `apply`. Anything you change afterwards makes it "custom" (no segment highlighted). |
| Governor | Kernel cpufreq governor for all policies | `scaling_available_governors`, applied to every policy | Written to all `policy*/scaling_governor` at once. |
| Energy preference | Intel HWP energy/performance hint (EPP) | `energy_performance_available_preferences` | Only present when the driver exposes it (intel_pstate/amd-pstate with HWP). Some governors refuse an EPP write; that failure is non-fatal. |
| Minimum / Maximum | Scaling limits shared by all cores | `scaling_min_freq` / `scaling_max_freq` | Sliders step 100 MHz, clamped to hardware limits. Dragging min above max (or vice versa) moves both bounds so the kernel never sees a crossed pair. |
| Per-core frequency | Current clock of each logical core | `scaling_cur_freq` | Grid columns 1–6 in the settings. Mini bar = fraction of the hw min–max range. |

`hwMin`/`hwMax` used above are `cpuinfo_min_freq`/`cpuinfo_max_freq` — the hardware range the
driver reports, which is what sliders and progress bars are scaled against.

## Temperature tab

| Stat | Meaning | Source | Notes |
|---|---|---|---|
| Hero: package | CPU package temperature | hwmon `coretemp`/`k10temp`/`zenpower`/`cpu_thermal` `temp*_input` | Prefers a `Package id`/`Tctl`/`Tdie` label; falls back to the first unlabeled sensor, then to the hottest core. millidegree input; °C or °F out. |
| Physical cores | One sensor per physical core | same hwmon, labels `Core N` | Sensors are per physical core: a 6c/12t CPU reports 6 readings, not 12. The hero caption shows the core/thread counts. |

Only CPUs that label sensors `Core N` (coretemp) get the grid; the tab says so when there is
just a package sensor.

## Usage tab

| Stat | Meaning | Source | Notes |
|---|---|---|---|
| Hero: CPU usage | Busy share of all cores since the previous poll | `/proc/stat` `cpu` line | `100 × (Δtotal − Δidle)/Δtotal`, where idle includes iowait. Needs two polls, so the very first reading is 0%. |
| Per-core usage | Same formula per logical CPU | `/proc/stat` `cpuN` lines | A core that appeared since the last poll reads 0 until it has a delta. |

## RAM tab

| Stat | Meaning | Source | Notes |
|---|---|---|---|
| Hero: used | Memory in use | `MemTotal − MemAvailable` | *Used* subtracts **available**, not free — caches that can be dropped don't count as used. Progress bar = used/total. |
| Used | Same number as the hero | `MemTotal − MemAvailable` | |
| Available | What apps can allocate before swapping starts | `MemAvailable` | Includes most reclaimable cache. This — not *Free* — is the number that matters. |
| Free | Completely untouched memory | `MemFree` | Usually small on Linux; low free is normal, not a problem. |
| Cached | Page cache + reclaimable slab | `Cached + SReclaimable` | |
| Buffers | Block-device cache | `Buffers` | Hidden when 0. |
| Shared | tmpfs/shmem usage | `Shmem` | Hidden when 0. |
| Total | Physical RAM | `MemTotal` | |
| Swap | Swap used / total | `SwapTotal − SwapFree` | Bar = used/total. Hidden when there is no swap. |
| ZRAM | RAM consumed by the compressed swap device / its uncompressed size | `/sys/block/zram*/mem_used_total`, `disksize` | Hidden without zram. "1.2/8.0 GiB" = 1.2 GiB of RAM holding ~8 GiB of compressed data. |

## GPU tab

One full set of cards per GPU. Detection walks `/sys/class/drm/card*`; the vendor ID picks the
fallback name and the NVIDIA path. Common ground (AMD/Intel sysfs, NVIDIA via nvidia-smi):

| Stat | Meaning | Source | Notes |
|---|---|---|---|
| Hero: name + usage | GPU name and its busy % | sysfs `product_name` (or nvidia-smi), AMD `gpu_busy_percent`, nvidia-smi `utilization.gpu` | Caption shows driver + version. A suspended GPU shows "powered down" instead — it is deliberately not queried. |
| Utilization: GPU / Memory controller / Encoder / Decoder | Busy % per engine | AMD: `gpu_busy_percent`; NVIDIA: `utilization.gpu/memory/encoder/decoder` | Encoder/decoder rows only when the driver reports them (NVIDIA). Intel reports no utilization without root. |
| Memory: VRAM | VRAM used / total | AMD `mem_info_vram_used/total`; NVIDIA `memory.used/total` | Bar = used/total. |
| Memory: VRAM free / reserved | Remaining / driver-reserved VRAM | AMD: computed `total − used` when not reported; NVIDIA: `memory.free`, `memory.reserved` | Reserved hidden when 0/absent. |
| Thermals: GPU / Memory | GPU and VRAM temperature | driver hwmon `temp1_input` (AMD/Intel); nvidia-smi `temperature.gpu/memory` | Same °C/°F setting as the CPU tab. |
| Thermals: Shutdown limit | Thermal shutdown temperature | nvidia-smi `temperature.gpu.tlimit` | |
| Thermals: Fan | Fan speed | hwmon `fan1_input` (RPM) and/or `pwm1` (→ %); nvidia-smi `fan.speed` (%) | Shows whatever mix exists, e.g. `2400 RPM  45%`. |
| Thermals: Clock limiters | Active throttle reasons | nvidia-smi `clocks_throttle_reasons.*` | e.g. "SW power cap, thermal slowdown". "None" when idle-throttled or nothing is limiting. |
| Power: Draw | Power draw now, with the configured limit | hwmon `power1_average`/`power1_input`; nvidia-smi `power.draw` (+ `power.limit`) | Watts. |
| Power: Limits | Default/min/max power cap | hwmon `power1_cap_default/min/max`; nvidia-smi `power.default/min/max_limit` | |
| Clocks: Graphics / Memory / SM / Video | Current engine clocks, with max in tow when different | AMD hwmon `freq1_input`; Intel `gt_cur_freq_mhz` (+ `gt_max_freq_mhz`); NVIDIA `clocks.current.*` (+ `clocks.max.*`) | SM is an NVIDIA thing; Video hidden when not reported. Max values are the driver's ceiling — on Intel that is the *configured* limit. |
| Clocks: Performance state | PCI-e P-state | nvidia-smi `pstate` | e.g. `P0`. |
| Bus & driver: PCIe link | Current link generation and width | nvidia-smi `pcie.link.gen/width.current` | Shows `(max …)` when the link downtrained from its maximum. |
| Bus & driver: VBIOS / Persistence / Compute mode / UUID / Serial / Display | Firmware and driver identity | nvidia-smi | Rows hidden when the driver does not report them. |
| Processes | Compute processes using this GPU | nvidia-smi `--query-compute-apps` | PID, process name and VRAM used. NVIDIA-only; graphics-only apps don't appear. |

## Fans tab

| Stat | Meaning | Source | Notes |
|---|---|---|---|
| Hero: speed | Fastest (or average, per setting) fan | see below | |
| Fan rows | One row per fan | hwmon `fan*_input`, using `fan*_label` when present | Fans owned by GPU drivers are excluded here — they show on the GPU tab instead. Bar entry uses the same max/avg rule. |

## Disk tab

| Stat | Meaning | Source | Notes |
|---|---|---|---|
| Hero: % used | Fill level of your chosen mount point | see below | Caption shows mount + `used/total`. Falls back to the first filesystem if your choice is not mounted. |
| Filesystem rows | One per mounted real filesystem | `/proc/mounts` filtered to real block devices and known filesystems (ext/btrfs/xfs/f2fs/vfat/exfat/ntfs/jfs/reiserfs/bcachefs) | Loop devices skipped; btrfs subvolumes collapse to one row (first mount wins); mount-point spaces (`\040`) decoded. |
| Sizes | `total`, `used`, `avail` | `stat -f` on the mount point | `avail` (stat's `bavail`) excludes blocks reserved for root, so `used + avail` can be less than `total`. Bar = used/(used+avail). |

## Battery tab

Data from `/sys/class/power_supply` (batteries only; device-scope batteries like a mouse's are
skipped). Energy values come from `energy_*` or, when hardware only reports charge, from
`charge_* × voltage` conversion.

### Hero

`charge% · status · time left (or "to 80%" while charging into a limit) · power draw`.
Time to empty is `energy/power`; while charging it is `(target − energy)/power`, where target
accounts for the stop threshold — so "1:20 to 80%" means until charging pauses at 80%, not 100%.
Unknown times (e.g. idle battery) are omitted.

### Overview page

| Stat | Meaning | Source | Notes |
|---|---|---|---|
| Power source | AC adapter or battery | `online` on Mains/USB*/UPS supplies | "Unknown" when nothing reports. Any adapter online = AC. |
| TLP profile / mode | Current TLP power profile (1.9+) or AC/battery/auto mode (older) | `tlpctl get`, else `tlp-stat -m` | Switching the profile needs no password when `tlp-pd` runs; otherwise it goes through the privileged helper. |
| TLP version | Installed TLP | `tlp --version` | |
| Health | Design capacity still available | `energy_full / energy_full_design` | 80% = the battery holds 80% of what it had new. |
| Capacity / Charge | Full capacity / current charge in Wh | `energy_full`, `energy_now` | Capacity shows "of design" too when known. |
| Charging power / Power draw | Rate now, signed by context | `power_now`, or `current_now × voltage_now` | Label flips to "Charging power" while charging. |
| Voltage | Pack voltage | `voltage_now` | |
| Charge cycles | Cumulative full-cycle count | `cycle_count` | Many vendors only report approximate values. |
| Temperature | Battery temperature | `temp` (tenths of a degree) | |
| Chemistry / Model | Li-ion/Li-poly etc.; vendor + model strings | `technology`, `manufacturer`, `model_name` | Rows hidden when empty. |

### Charging page

| Stat | Meaning | Notes |
|---|---|---|
| Preset: Full / Balanced / Lifespan | Threshold pairs 96–100 / 75–80 / 50–60 | A preset is just both sliders set at once; the highlighted segment is derived from the live thresholds, so a manual 60/80 shows as custom. |
| Start charging below | Start threshold | Only shown when the hardware has a start threshold. Moving start to/over stop drags stop up (min gap 5 %). |
| Stop charging at | Stop threshold | Slider starts at 20: below that many laptops stop charging entirely and never recover without a reset. TLP's own supported range (from `tlp-stat -b`) narrows it further when known. |
| Charge to full | One-off charge to 100% | Lifts the stop threshold to 100 now; configured limit returns at next boot or via *Restore*. Works without TLP. |
| Charge once | Charge to the limit one time | TLP `chargeonce` — useful after *force discharge* stopped early. TLP only. |
| Restore limits | Re-apply configured thresholds | TLP `setcharge` without numbers. |
| Charge behaviour | Kernel-level `auto` / `inhibit-charge` (pause) / `force-discharge` | Reads/writes `charge_behaviour`, where the kernel offers it. This pauses charging or discharges through the battery while on AC. |
| Maintenance: Discharge / Recalibrate | ThinkPad battery maintenance routines | Behind a tap-twice confirmation; both need the charger connected and drain the battery fully (recalibrate then recharges). |

Persistence: with *Keep charge limits across reboots* on and TLP installed, every change also
writes `START/STOP_CHARGE_THRESH_BATx` to the plugin's `/etc/tlp.d/99-dms-cpufreq.conf`.
Without TLP, thresholds go straight to sysfs and last until reboot.

### Tuning page

Edits whitelisted TLP parameters for the profile you pick (AC / battery, or
Performance/Balanced/Power-saver sets on TLP 1.9+). Each field shows the **effective** value
TLP reports and where it came from:

* "Overridden by /etc/tlp.conf" — that file is read last and wins over the plugin's drop-in;
  comment the key out there or the field has no effect.
* "Reset to TLP default" — removes that one key from the drop-in.
* The reset-all button clears the whole drop-in (tap twice).

Governor/EPP/platform options in Tuning are read live from the kernel, so they match what your
system actually offers. Sliders show TLP's default position while a parameter is unset
(max performance 100, audio timeout 10 s, min performance 0).

## Missing data

* "…" in the bar / "Waiting for data" in the popout — helper not installed or not answering:
  run `install.sh` from the plugin folder (see the README).
* "–" — this hardware/driver does not report that value; the row is usually hidden instead.
* Whole metric hidden — the hardware does not report the metric at all (no battery, no fans, …),
  or its *show tab in popout* setting is off.
