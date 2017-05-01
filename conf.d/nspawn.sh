#!/bin/bash
source $1
for image in $(machinectl list-images | tail -n +2 | head -n -1 | cut -d " " -f 1); do
    machinectl status $image &> /dev/null
    if [ $? -ne 0 ]; then
        echo "$image is not running"
    fi
done
