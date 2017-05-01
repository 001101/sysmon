#!/bin/bash
source $USE_CORE

if [ -z "$MATRIX_API" ]; then
    echo "matrix api host is required"
    exit 1
fi

if [ -z "$MATRIX_ROOM" ]; then
    echo "matrix room is required"
    exit 1
fi

if [ -z "$MATRIX_TOKEN" ]; then
    echo "matrix token is required"
    exit 1
fi

export today=$(date +%Y-%m-%d)
export yesterday=$(date +%Y-%m-%d -d yesterday)
rm -f /tmp/*$REPORT_SUFFIX
report=$(mktemp --suffix "$REPORT_SUFFIX")
for conf in $(find $CONFD -type f -name "*.sh"); do
    named=$(basename $conf | sed "s/\.sh//g")
    if [ ! -z "$monitor_disabled" ]; then
        echo $named | grep -E -q "$monitor_disabled"
        if [ $? -eq 0 ]; then
            echo $named" is disabled"
            continue
        fi
    fi
    $conf $USE_CORE | sed "s/^/$named -> /g" >> $report
done

if [ -s $report ]; then
    do_report=""
    for r in $(cat $report | cut -d " " -f 1 | uniq | sort); do
        do_report=$do_report" "$r
    done
    do_report="monitor alerted: "$(echo $HOSTNAME)" -> "$(echo $do_report | sed "s/ /,/g")
    as_json=$(echo "{\"msgtype\":\"m.text\", \"body\":\""$do_report"\"}")
    curl -XPOST -d "$as_json" "$MATRIX_API/_matrix/client/r0/rooms/$MATRIX_ROOM/send/m.room.message?access_token=$MATRIX_TOKEN"
else
    echo $report" is empty"
fi
