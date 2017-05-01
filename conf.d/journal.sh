#!/bin/bash
source $1
skip=""
flag=""
if [ ! -z "$journal_ignore" ]; then
    skip=$journal_ignore
    flag=-v
fi
journalctl -p err --since yesterday --until today | tail -n +2 | grep -E $flag "${skip}"
