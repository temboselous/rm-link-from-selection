#!/bin/bash
# Remove the mod from the tablet and restart its interface. Links already made stay
# stored inside their documents and show again if the mod is reinstalled.
set -euo pipefail
HOST="${RM_HOST:-root@10.11.99.1}"
ssh -o BatchMode=yes -o ConnectTimeout=10 "$HOST" '
rm -f /home/root/xovi/exthome/qt-resource-rebuilder/linkFromSelection.qmd
/home/root/xovi/start >/dev/null 2>&1
echo "removed: the interface has restarted without the mod"
'
