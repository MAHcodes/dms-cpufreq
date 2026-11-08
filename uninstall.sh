#!/usr/bin/env bash
set -euo pipefail
plugins=${XDG_CONFIG_HOME:-$HOME/.config}/DankMaterialShell/plugins
[ -L "$plugins/CpuFreq" ] && rm -v "$plugins/CpuFreq"
sudo rm -fv /usr/local/bin/dms-cpufreqctl /usr/share/polkit-1/actions/dev.dms.cpufreq.policy
if [ -e /etc/tlp.d/99-dms-cpufreq.conf ]; then
  echo "Note: /etc/tlp.d/99-dms-cpufreq.conf was left in place (your TLP tuning and charge limits)."
  echo "Remove it with: sudo rm /etc/tlp.d/99-dms-cpufreq.conf && sudo tlp start"
fi
echo "Removed. Run: dms restart"
