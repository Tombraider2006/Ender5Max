#!/bin/sh

FILE="/usr/data/guppyscreen/calibration.json"
BACKUP="/usr/data/guppyscreen/calibration.json.bak"

if [ -f "$FILE" ]; then
    mv "$FILE" "$BACKUP"
fi

echo "иди жми крестики калибровки"
sleep 2
reboot

