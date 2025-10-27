#!/bin/bash

(

flock -n 200 || exit 1

source /home/user/task9/monitoring.conf

rm -f .processing_lines.tmp
rm -f $MAIL_FILE

if [[ -e "$LAST_START_FILE" ]]
    then
        old_start_time=$(cat $LAST_START_FILE | xargs echo)
    else
        old_start_time=0000000000
fi

new_start_time=$(date +%s)
echo $new_start_time > $LAST_START_FILE

while IFS= read -r line
do
    timestamp=$(echo $line | cut -d ' ' -f4-5 | tr '/' '\040' | sed 's/:/ /'| tr -d '[' | tr -d ']'| xargs -I {} date -d {} +%s)
    if [[ $timestamp -gt $old_start_time ]]
        then
        echo $line >> .processing_lines.tmp
    fi
done < $LOG_FILE


if [[ -e ".processing_lines.tmp" ]]
    then
        :
    else
        echo "Regular nginx log stats from ($(date -d @$old_start_time)) to ($(date -d @$new_start_time)). No new info for now :(" # | mail -s "Monitoring results from ($(date -d @$old_start_time)) to ($(date -d @$new_start_time))" "admin@local.com"
        exit 0
fi


echo "From ($(date -d @$old_start_time)) to ($(date -d @$new_start_time)) this info was collected this stats:" >> $MAIL_FILE


echo "List of IP-addresses and number of connection attempts:" >> $MAIL_FILE
cat .processing_lines.tmp | cut -d' ' -f1 | sort | uniq -c | sort -rn >> $MAIL_FILE
echo "" >> $MAIL_FILE


echo "List of URLs and number requests:" >> $MAIL_FILE
cat .processing_lines.tmp | cut -d'"' -f2 | cut -d" " -f2 | sort | uniq -c | sort -rn >> $MAIL_FILE
echo "" >> $MAIL_FILE


echo "List of response codes and number of occurrences:" >> $MAIL_FILE
cat .processing_lines.tmp | cut -d'"' -f3 | cut -d" " -f2 | sort | uniq -c | sort -rn >> $MAIL_FILE
echo "" >> $MAIL_FILE


echo "List of errors:" >> $MAIL_FILE
while IFS= read -r line
do
    response_code=$(echo $line | cut -d'"' -f3 | cut -d" " -f2)
    if [[ $response_code =~ ^4 ]]
        then
        echo APPLICATION_ERROR_COMMITTED \($response_code\) at $(echo $line | cut -d ' ' -f4-5 | tr -d '[' | tr -d ']') from $(echo $line | cut -d' ' -f1) accessing URL $(echo $line | cut -d'"' -f2 | cut -d" " -f2) >> $MAIL_FILE
    elif [[ $response_code =~ ^5 ]]
        then
        echo SERVER_ERROR_COMMITTED \($response_code\) at $(echo $line | cut -d ' ' -f4-5 | tr -d '[' | tr -d ']') from $(echo $line | cut -d' ' -f1) accessing URL $(echo $line | cut -d'"' -f2 | cut -d" " -f2) >> $MAIL_FILE
    fi
done < .processing_lines.tmp
rm -f .processing_lines.tmp

echo "" >> $MAIL_FILE

echo "Regular nginx log stats from ($(date -d @$old_start_time)) to ($(date -d @$new_start_time))" # | mail -s "Monitoring results from ($(date -d @$old_start_time)) to ($(date -d @$new_start_time))" -A "$MAIL_FILE" "admin@local.com"

) 200> /var/lock/monitoring.lock