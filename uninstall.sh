#!/usr/bin/env bash
set -euo pipefail
plugins=${XDG_CONFIG_HOME:-$HOME/.config}/DankMaterialShell/plugins
[ -L "$plugins/CpuFreq" ] && rm -v "$plugins/CpuFreq"
sudo rm -fv /usr/local/bin/dms-cpufreqctl /usr/share/polkit-1/actions/dev.dms.cpufreq.policy
echo "Removed. Run: dms restart"
