#!/bin/bash
source $1
skip=""
flag=""
if [ ! -z "$journal_ignore" ]; then
    skip=$journal_ignore
    flag=-v
fi
journalctl -p err --since "$yesterday 12:00:00" --until "$today 12:00:00" | tail -n +2 | grep -v "\-\- Reboot \-\-" | grep -v "^[ ]" | grep -E $flag "${skip}"
