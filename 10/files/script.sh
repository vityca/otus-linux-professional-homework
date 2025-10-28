#!/bin/bash
exec 2> /dev/null
echo -e "PID\tTTY\tSTAT\tTIME\tCOMMAND"

find /proc/ -maxdepth 1 -type d -regex '^.*[0-9]+$' | while read -r i
do
    PID=$(basename $i)

    if [[ -e "/proc/$PID/fd/0" ]]
        then
            TTY=$(ls -l /proc/$PID/fd/0 | cut -d' ' -f11)
        else
            TTY="?"
    fi

    STAT=$(cat /proc/$PID/stat | cut -d' ' -f3)
    USER_TIME=$(cat /proc/$PID/stat | cut -d' ' -f14)
    KERNEL_TIME=$(cat /proc/$PID/stat | cut -d' ' -f15)
    TIME=$(( ($USER_TIME +  $KERNEL_TIME) / $(getconf CLK_TCK) ))
    COMMAND="$(cat /proc/$PID/cmdline | tr -d '\0')"

    if [[ -z $COMMAND ]]
        then
            COMMAND="[$(cat /proc/$PID/comm)]"
    fi
    echo -e "$PID\t$TTY\t$STAT\t$TIME\t$COMMAND"

done