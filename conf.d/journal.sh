#!/bin/bash
source $1
skip=""
flag=""
if [ ! -z "$journal_ignore" ]; then
    skip=$journal_ignore
    flag=-v
fi
last_reboot=$(uptime --since)
use_since="${yesterday} 12:00:00"
comp_last=$(date -d $(echo $last_reboot | sed "s/ /T/g") +%s)
comp_yest=$(date -d $(echo $use_since | sed "s/ /T/g") +%s)
if [ $comp_last -gt $comp_yest ]; then
    use_since="$last_reboot"
fi
journalctl -p err --since "$use_since" --until "$today 12:00:00" | tail -n +2 | grep -v "\-\- Reboot \-\-" | grep -v "^[ ]" | grep -E $flag "${skip}"
