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

rules="rules:"
export today=$(date +%Y-%m-%d)
export yesterday=$(date +%Y-%m-%d -d yesterday)
rm -f /tmp/*$REPORT_SUFFIX
report=$(mktemp --suffix "$REPORT_SUFFIX")
for conf in $(find $CONFD -type f -name "*.sh"); do
    named=$(basename $conf | sed "s/.sh//g")
    enabled=$(is-conf-configured $named)
    if [ $enabled -ne $IS_ENABLED ]; then
        continue
    fi
    rules=$rules" "$conf
    echo "running $conf"
    $conf $USE_CORE | sed "s/^/$named -> /g" >> $report
done

do_report="$HOSTNAME checked"
reporting=0
if [ -s $report ]; then
    do_report="processed rules: $rules "
    for r in $(cat $report | cut -d " " -f 1 | uniq | sort); do
        do_report=$do_report" "$r
    done
    do_report="monitor alerted: "$(echo $HOSTNAME)" -> "$(echo $do_report | sed "s/ /,/g")
    do_report=$do_report"
===$HOSTNAME (first $HEAD)==="
    do_report=$do_report"
"$(cat $report | head -n $HEAD)
    do_report=$do_report"
===/end $HOSTNAME==="
    reporting=1
else
    echo "$report is empty (ran: $rules)"
    check=$(date +%u)
    if [ $check == $WEEKLY ]; then
        do_report=$do_report" executed ($rules)"
        reporting=1
    fi
fi
if [ $reporting -eq 1 ]; then
    echo "$do_report"
    use_perl="use JSON; print(encode_json {\"body\" => \"$do_report\"}); print(\".{\\\"msgtype\\\":\\\"m.text\\\"}\");"
    as_json=$(perl -e "$use_perl")
    as_json=$(echo $as_json | sed "s/}.{/,/g")
    echo $as_json
    curl -XPOST -d "$as_json" "$MATRIX_API/_matrix/client/r0/rooms/$MATRIX_ROOM/send/m.room.message?access_token=$MATRIX_TOKEN"
fi
