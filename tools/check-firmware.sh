#!/bin/bash
# After a firmware update: read the tablet's version and name table, keep a copy under
# device/<version>/, and say whether the mod still fits. Installs nothing.
set -euo pipefail
cd "$(dirname "$0")/.."
QMD="${1:-src/linkFromSelection.qmd}"
HOST="${RM_HOST:-root@10.11.99.1}"
DIR=/home/root/xovi/exthome/qt-resource-rebuilder
SSH="ssh -o BatchMode=yes -o ConnectTimeout=10 $HOST"

OS="$($SSH 'sed -n "s/^IMG_VERSION=\"\(.*\)\"/\1/p" /etc/os-release')"
echo "tablet firmware: $OS"

mkdir -p "device/$OS"
scp -q -o BatchMode=yes "$HOST:$DIR/hashtab" "device/$OS/hashtab"
TABLE="$(python3 tools/hashtab.py version "device/$OS/hashtab")"
if [ "$TABLE" != "$OS" ]; then
    echo "The tablet's name table was built on $TABLE, not $OS."
    echo "Rebuild it on the tablet first:  ssh $HOST /home/root/xovi/rebuild_hashtable"
    exit 2
fi

if python3 tools/hashtab.py check "device/$OS/hashtab" "$QMD"; then
    echo "No missing names. Next: tools/install.sh, then try a link in each direction."
else
    echo "The lines above use names that $OS no longer has. Fix those before installing."
    exit 1
fi
