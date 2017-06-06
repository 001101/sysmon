#!/bin/bash
source $1
except=$nspawn_exceptions
for image in $(machinectl list-images | tail -n +2 | head -n -1 | cut -d " " -f 1); do
    machinectl status $image &> /dev/null
    if [ $? -ne 0 ]; then
        grp=0
        if [ ! -z "$except" ]; then
            echo "$image" | grep -v -E -q "$except"
            grp=$?
        fi
        if [ $grp -eq 0 ]; then
            echo "$image is not running"
        fi
    fi
done
