#!/bin/bash
source $1
if [ ! -z "$proc_names" ]; then
    for p in $(echo "$proc_names"); do
        id=$(pidof $p)
        if [ -z $id ]; then
            echo "$p is not running"
        fi
    done
fi
