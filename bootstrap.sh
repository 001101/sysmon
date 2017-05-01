#!/bin/bash
USE_CORE=/opt/system-monitor/core
export USE_CORE
source $USE_CORE
if type git &> /dev/null; then
    cd ${LOCATION} && git pull
fi
hour=$(date +%H)
if [ $hour -eq $TRIGGER_HOUR ]; then
    ${LOCATION}mon.sh
fi
