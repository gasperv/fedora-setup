#!/usr/bin/env bash
# Toggle LAN-party mode: puts the wired NIC into firewalld's "trusted" zone
# (all incoming allowed) so hosting + LAN server discovery work. Turn it off after.
# Usage: lan-mode on | off | status

set -euo pipefail
NIC=$(ip -o route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<NF;i++) if($i=="dev") print $(i+1)}')
[[ -z "$NIC" ]] && { echo "No active network interface found."; exit 1; }
CON=$(nmcli -g GENERAL.CONNECTION device show "$NIC")

case "${1:-status}" in
  on)  sudo nmcli connection modify "$CON" connection.zone trusted
       sudo nmcli connection up "$CON" >/dev/null
       echo "LAN mode ON  ($NIC / $CON -> trusted)";;
  off) sudo nmcli connection modify "$CON" connection.zone ""
       sudo nmcli connection up "$CON" >/dev/null
       echo "LAN mode OFF ($NIC / $CON -> default zone)";;
  status) echo "$NIC / $CON zone: $(sudo firewall-cmd --get-zone-of-interface="$NIC" 2>/dev/null || echo default)";;
  *) echo "Usage: lan-mode on|off|status"; exit 1;;
esac
