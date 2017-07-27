#!/bin/bash
source /etc/epiphyte.d/sysmon.conf
OUTPUT=/tmp/sysmon.last

# file checking
CHECK_SIZE=1
NO_CHECK_SIZE=0

# report an item
function report-item()
{
    echo "$1 -> $2"
}

# file exists and populated
function file-exist-size()
{
    if [ -e $1 ]; then
        if [ $2 -eq $CHECK_SIZE ]; then
            if [ ! -s $1 ]; then
                report-item $1 "is empty/zero"
            fi
        fi
    else
        report-item $1 "does not exist..."
    fi
}

# not empty file
function not-empty()
{
    file-exist-size $1 $CHECK_SIZE
}

# service enabled
function service-enabled()
{
    systemctl is-enabled $1 | grep -q "enabled"
    if [ $? -ne 0 ]; then
        report-item $1 "service not enabled..."
    fi
}

_etcgit() {
    if [ -d /etc/.git ]; then
        cd /etc && git diff-index --name-only HEAD --
        cd /etc && git status -sb | grep 'ahead'
    fi
}

_iptables() {
    _nspawn=$(systemd-detect-virt)
    if [[ $_nspawn != "systemd-nspawn" ]]; then
        not-empty "/etc/iptables/iptables.rules"
        service-enabled iptables
    fi
}

_journalerr() {
    today=$(date +%Y-%m-%d)
    yesterday=$(date +%Y-%m-%d -d yesterday)
    last_reboot=$(uptime --since)
    use_since="${yesterday} 12:00:00"
    comp_last=$(date -d $(echo $last_reboot | sed "s/ /T/g") +%s)
    comp_yest=$(date -d $(echo $use_since | sed "s/ /T/g") +%s)
    if [ $comp_last -gt $comp_yest ]; then
        use_since="$last_reboot"
    fi
    journalctl -p err --since "$use_since" --until "$today 12:00:00" | tail -n +2 | grep -v "\-\- Reboot \-\-" 
}

_containers() {
    for image in $(machinectl list-images | tail -n +2 | head -n -1 | cut -d " " -f 1); do
        machinectl status $image &> /dev/null
        if [ $? -ne 0 ]; then
            echo "$image is not running"
        fi
    done
}

_all() {
    _etcgit
    _iptables
    _journalerr
    _containers
}

pattern=""
flag=""
if [ ! -z "$IGNORES" ]; then
    flag="-v"
    pattern="$IGNORES"
fi

_all 2>&1 | grep $flag "$pattern" > $OUTPUT
if [ -s $OUTPUT ]; then
    echo "sysmon errors reported" | smirc
    cat $OUTPUT | smirc --private
fi
