#!/bin/bash
# Check the mod against the tablet's firmware, install it, and back out if the tablet's
# interface cannot start with it. Usage: tools/install.sh [file.qmd]
set -euo pipefail
cd "$(dirname "$0")/.."
QMD="${1:-src/linkFromSelection.qmd}"
HOST="${RM_HOST:-root@10.11.99.1}"
DIR=/home/root/xovi/exthome/qt-resource-rebuilder
SSH="ssh -o BatchMode=yes -o ConnectTimeout=10 $HOST"

# A hashed name the firmware lacks stops the interface from starting, so check first
# against the tablet's own table, never a saved copy.
TAB="$(mktemp)"
trap 'rm -f "$TAB"' EXIT
scp -q -o BatchMode=yes "$HOST:$DIR/hashtab" "$TAB"
python3 tools/hashtab.py check "$TAB" "$QMD"

scp -q -o BatchMode=yes "$QMD" "$HOST:$DIR/linkFromSelection.qmd"
$SSH '
Q='"$DIR"'/linkFromSelection.qmd
/home/root/xovi/start >/dev/null 2>&1
sleep 14; A=$(pidof xochitl || true); sleep 6; B=$(pidof xochitl || true)
if [ -z "$B" ] || [ "$A" != "$B" ]; then
    rm -f "$Q"; /home/root/xovi/start >/dev/null 2>&1
    echo "FAILED: interface kept restarting, mod removed again. Log:"
    journalctl -u xochitl --since "-60s" --no-pager | grep -iE "cannot|qmldiff.*(fail|error)" | tail -n 20
    exit 1
fi
echo "installed: interface is up with the mod loaded"
'
