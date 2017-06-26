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
    named=$(basename $conf | sed "s/.sh//g")
    enabled=$(is-conf-configured $named)
    if [ $enabled -ne $IS_ENABLED ]; then
        continue
    fi
    echo "running $conf"
    $conf $USE_CORE | sed "s/^/$named -> /g" >> $report
done

do_report="$HOSTNAME checked"
reporting=0
if [ -s $report ]; then
    do_report=""
    for r in $(cat $report | cut -d " " -f 1 | uniq | sort); do
        do_report=$do_report" "$r
    done
    do_report=$do_report"
\`\`\`"
    do_report=$do_report"
"$(cat $report | head -n 5)
    do_report=$do_report"
\`\`\`"
    do_report="monitor alerted: "$(echo $HOSTNAME)" -> "$(echo $do_report | sed "s/ /,/g")
    reporting=1
else
    echo "$report is empty"
    check=$(date +%u)
    if [ $check == $WEEKLY ]; then
        reporting=1
    fi
fi
if [ $reporting -eq 1 ]; then
    use_perl="use JSON: print(encode_json {\"body\" => \"$do_report\", \"msgtype\":\"m.texs\"});"
    as_json=(perl -e "$use_perl")
    curl -XPOST -d "$as_json" "$MATRIX_API/_matrix/client/r0/rooms/$MATRIX_ROOM/send/m.room.message?access_token=$MATRIX_TOKEN"
fi
