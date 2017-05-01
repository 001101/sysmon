#!/bin/bash
USE_CORE=/opt/system-monitor/core
export USE_CORE
source $USE_CORE
cd ${LOCATION} && git pull
${LOCATION}mon.sh
