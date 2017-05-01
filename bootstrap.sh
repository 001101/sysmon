#!/bin/bash
USE_CORE=/opt/system-monitor/core
export USE_CORE
source $USE_CORE
hour=$(date +%H)
if [ ! -z $1 ]; then
    if [ $1 == "force" ]; then
        hour=$TRIGGER_HOUR
    fi
fi
if [ $hour -eq $TRIGGER_HOUR ]; then
    if type git &> /dev/null; then
        cd ${LOCATION} && git pull
    fi
    ${LOCATION}mon.sh
fi
