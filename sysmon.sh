#!/bin/bash
source /etc/epiphyte.d/sysmon.conf
OUTPUT=/tmp/sysmon.last
LAST_RAN=/var/tmp/sysmon.lastran
NAME="sysmon (_VERSION_)"

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
function service-is()
{
    systemctl is-enabled $1 | grep -q "$2"
    if [ $? -ne 0 ]; then
        report-item $1 "service not $2..."
    fi
}

_pacmanconf()
{
    cat /etc/pacman.conf | grep -v "^#" | grep -v "^$" | grep http | grep "http:"
}

function service-enabled()
{
    service-is $1 "enabled"
}

function service-disabled()
{
    service-is $1 "disabled"
}

_disabled()
{
    service-disabled "systemd-resolved"
    pacman -Qi ntp &> /dev/null
    if [ $? -eq 0 ]; then
        service-disabled "ntpd"
    fi
}

_etcgit() {
    if [ -d /etc/.git ]; then
        cd /etc && git update-index -q --refresh
        cd /etc && git diff-index --name-only HEAD --
        cd /etc && git status -sb | grep 'ahead'
    fi
}

_btrfs() {
    _nspawn=$(systemd-detect-virt)
    if [[ $_nspawn != "systemd-nspawn" ]]; then
        service-enabled btrfs-maintain-monthly.timer
    fi
}

_iptables() {
    _nspawn=$(systemd-detect-virt)
    if [[ $_nspawn != "systemd-nspawn" ]]; then
        not-empty "/etc/iptables/iptables.rules"
        service-enabled iptables
    fi
}


_pids() {
    cnt=$(pidof $1 | sed "s/ /\n/g" | wc -l)
    if [ $cnt -gt $2 ]; then
        echo "$1 has $cnt processes (exceeds $2)"
    fi
}

_processes() {
    if [ ! -z "PROCESS_PIDS" ]; then
        for p in $(echo "$PROCESS_PIDS"); do
            p_name=$(echo $p | cut -d ":" -f 1)
            p_cnt=$(echo $p | cut -d ":" -f 2)
            _pids "$p_name" "$p_cnt"
        done
    fi
}

_journalerr() {
    today=$(date +%Y-%m-%d)
    yesterday=$(date +%Y-%m-%d -d yesterday)
    last_reboot=$(uptime --since)
    use_since="${yesterday} 12:00:00"
    comp_last=$(date -d $(echo $last_reboot | sed "s/ /T/g") +%s)
    comp_yest=$(date -d $(echo $use_since | sed "s/ /T/g") +%s)
    use_comp=$comp_yest
    if [ $comp_last -gt $comp_yest ]; then
        use_since="$last_reboot"
        use_comp=$comp_last
    fi
    has_until=$(date -d $(echo "${today}T12:00:00") +%s)
    if [ $use_comp -lt $has_until ]; then
        journalctl -p err --since "$use_since" --until "$today 12:00:00" | grep -v "^\-\-" | tail -n +2     
    fi
}

_containers() {
    for image in $(machinectl list-images | tail -n +2 | head -n -1 | cut -d " " -f 1); do
        machinectl status $image &> /dev/null
        if [ $? -ne 0 ]; then
            echo "$image is not running"
        fi
    done
}

_disk_use() {
    _usage=$(df -h / | sed "s/ \+/ /g" | cut -d " " -f 5 | tail -n +2 | sed "s/%//g")
    if [ $_usage -gt 70 ]; then
        echo "disk usage at $_usage exceeds threshold"
    fi
}

_last_ran() {
    if [ -e $LAST_RAN ]; then
        for l in $(cat $LAST_RAN); do
            name=$(echo $l | cut -d "=" -f 1)
            date=$(echo $l | cut -d "=" -f 2)
            date=$(date -d $date +%s)
            week=$(date -d "7 days ago" +%s)
            if [ $date -lt $week ]; then
                echo "$name has not recently run"
            fi
        done
    fi
}

_all() {
    _etcgit
    _iptables
    _journalerr
    _containers
    _disk_use
    _last_ran
    _processes
    _disabled
    _pacmanconf
    _btrfs
}

pattern=""
flag=""
if [ ! -z "$IGNORES" ]; then
    flag="-v -E"
    pattern="$IGNORES"
fi

_all 2>&1 | grep $flag "$pattern" > $OUTPUT
if [ -s $OUTPUT ]; then
    echo "$NAME errors reported" | smirc
    cat $OUTPUT | smirc --private
else
    echo "$NAME completed successfully" | smirc --private
fi
