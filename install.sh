#!/usr/bin/env bash
# Installs the root helper + polkit policy (sudo, once) and links the plugin into DMS.
#
#   ./install.sh           no password prompts when changing CPU settings (active local session)
#   ./install.sh --auth    ask for admin authentication instead (cached for a few minutes)
set -euo pipefail
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
plugins=${XDG_CONFIG_HOME:-$HOME/.config}/DankMaterialShell/plugins
target=$plugins/CpuFreq

mode=open
case "${1:-}" in
  "") ;;
  --auth) mode=auth ;;
  *) echo "usage: $0 [--auth]" >&2; exit 2 ;;
esac

policy=$(mktemp)
trap 'rm -f "$policy"' EXIT
if [ "$mode" = auth ]; then
  sed 's#<allow_active>yes</allow_active>#<allow_active>auth_admin_keep</allow_active>#' \
    "$here/helper/dev.dms.cpufreq.policy" >"$policy"
else
  cp "$here/helper/dev.dms.cpufreq.policy" "$policy"
fi

echo "==> Installing helper and polkit policy ($mode) - needs sudo"
sudo install -Dm755 "$here/helper/dms-cpufreqctl" /usr/local/bin/dms-cpufreqctl
sudo install -Dm644 "$policy" /usr/share/polkit-1/actions/dev.dms.cpufreq.policy

# Older versions of this plugin documented a rules.d file; remove it if present.
[ -e /etc/polkit-1/rules.d/49-dms-cpufreq.rules ] && sudo rm -f /etc/polkit-1/rules.d/49-dms-cpufreq.rules

# When installed from the plugin registry this script already lives inside the plugins
# directory, so there is nothing to link. Only link when run from a separate checkout.
here_real=$(readlink -f "$here")
plugins_real=$(readlink -f "$plugins" 2>/dev/null || echo "$plugins")
case "$here_real" in
  "$plugins_real"/*)
    echo "==> Plugin already lives in $plugins, not linking"
    ;;
  *)
    echo "==> Linking plugin into $plugins"
    mkdir -p "$plugins"
    if [ -L "$target" ] || [ ! -e "$target" ]; then
      ln -sfn "$here" "$target"
    else
      echo "$target already exists and is not a symlink; leaving it alone" >&2
      exit 1
    fi
    ;;
esac

cat <<MSG

Done ($mode mode). polkit picks up the policy immediately.
  1. DMS Settings -> Plugins -> Scan for Plugins -> enable "System Monitor"
  2. Add it to a DankBar section
  3. dms restart   (or: dms ipc call plugins reload cpuFreq)

Battery tab: charge limits work on supported laptops with or without TLP.
TLP profiles and tuning need TLP (https://linrunner.de/tlp); re-run this
installer after updating the plugin so the helper is replaced too.
MSG
