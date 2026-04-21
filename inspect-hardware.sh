#!/usr/bin/env bash
# Usage: ./inspect-hardware.sh [remote_host]
# Default remote_host is nixos@installer.local
REMOTE="${1:-nixos@installer.local}"
SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=10 -q"

echo "=== Hardware Inspection for $REMOTE ==="

# 1. Disk IDs
echo -e "\n[Disk IDs (by-id)]"
ssh $SSH_OPTS "$REMOTE" "ls -l /dev/disk/by-id/ | grep -v 'part' | grep 'nvme' | awk '{print \$9}'" || echo "No NVMe disks found."

# 2. GPU Bus IDs (Format: PCI:X:Y:Z)
echo -e "\n[GPU Bus IDs]"
ssh $SSH_OPTS "$REMOTE" "lspci | grep -E 'VGA|3D'" | while read -r line; do
    # Convert 00:02.0 to PCI:0:2:0
    BUS_ID=$(echo "$line" | awk '{print $1}' | sed -E 's/([0-9a-fA-F]+):([0-9a-fA-F]+)\.([0-9a-fA-F]+)/PCI:\1:\2:\3/' | sed 's/PCI:0000:/PCI:/')
    echo "$BUS_ID -> $line"
done

# 3. Main Internal Keyboard
echo -e "\n[Main Internal Keyboard (Candidate)]"
ssh $SSH_OPTS "$REMOTE" "cat /proc/bus/input/devices" | awk '
    /Name=/ {name=$0}
    /Vendor=/ {ids=$0}
    /Handlers=/ {handlers=$0}
    /^[[:space:]]*$/ {
        # Bus=0011 is typical for PS/2 internal keyboards
        if (ids ~ /Bus=0011/ && handlers ~ /kbd/) {
            # Extract Vendor and Product hex
            if (match(ids, /Vendor=([0-9a-fA-F]+) Product=([0-9a-fA-F]+)/, m)) {
                print name "\n  ID: " m[1] ":" m[2] " (Vendor:Product)"
            } else {
                print name "\n  " ids
            }
        }
    }'

# 4. Battery Threshold Support
echo -e "\n[Battery Threshold Support]"
ssh $SSH_OPTS "$REMOTE" "ls /sys/class/power_supply/BAT*/charge_*_threshold 2>/dev/null" || echo "Standard threshold paths (charge_control_*) not found."

echo -e "\n=== End of Inspection ==="
