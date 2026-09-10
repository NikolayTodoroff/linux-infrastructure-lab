#!/bin/bash

LOGFILE="/var/log/health-check.log"
SEPARATOR="============================================"

exec >> "$LOGFILE" 2>&1

echo "$SEPARATOR"
echo "Health Check — $(date +'%Y-%m-%d %H:%M:%S')"
echo "$SEPARATOR"

echo ""
echo "--- Disk Usage ---"
df -h /mnt/projects /mnt/logs /srv/nfs

echo ""
echo "--- Memory & Swap ---"
free -h

echo ""
echo "--- Service Status ---"
echo "MariaDB:    $(systemctl is-active mariadb)"
echo "NFS Server: $(systemctl is-active nfs-kernel-server)"
echo "Nginx:      $(systemctl is-active nginx)"

echo ""
echo "--- Network ---"
if ping -c 1 -W 2 gateway > /dev/null 2>&1; then
    echo "Gateway:  reachable"
else
    echo "Gateway:  UNREACHABLE"
fi

if ping -c 1 -W 2 1.1.1.1 > /dev/null 2>&1; then
    echo "Internet: reachable"
else
    echo "Internet: UNREACHABLE"
fi

echo ""
