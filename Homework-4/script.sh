#!/usr/bin/env bash

#Top 10 requested addresses/url
top=10

lockfile=/var/local/nginx_parse.lock
nginx_log='access.log'


if [ -f $lockfile ]; then
    echo "${0} is already running"
    exit 1
fi

touch $lockfile
echo "LockFile $lockfile now creating..."


trap 'rm -f "$lockfile"; exit $?' INT TERM EXIT

#From time to analyze the logs
fromDate=$(date --date '-1 hour' '+%d/%b/%Y:%T')
awk -v parseDate="$(date --date '-1 hour' '+%d/%b/%Y:%T')" '{gsub(/^[\[\t]+/, "", $4);}; $4 > parseDate' $nginx_log > data.log

#X IP addresses with the highest number of requests
ip=$(sed -nr 's/([[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3})\s\-\s\-\s[[:digit:]]{1,2}\/[[:alpha:]]+\/[[:digit:]]{4}:[[:digit:]]+:[[:digit:]]+:[[:digit:]]+\s\+[[:digit:]]+\]\s"GET (.*\/)\sHTTP.*/\1/p' data.log | sort | uniq -c | sort -nr | head -n $top)


#Y requested addresses with the highest number of requests
url=$(sed -nr 's/[[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}\s\-\s\-\s[[:digit:]]{1,2}\/[[:alpha:]]+\/[[:digit:]]{4}:[[:digit:]]+:[[:digit:]]+:[[:digit:]]+\s\+[[:digit:]]+\]\s"GET (.*\/)\sHTTP.*/\1/p' data.log | sort | uniq -c | sort -nr | head -n $top)

#All Http codes
httpCodes=$(awk '{print $9}' data.log | sort | uniq -c | sort -rn)

#Declare an array to save errors
errorAray=()

#Error Http codes
for i in {400..526}
do
    countError=$(awk '($9 ~ /'"$i"'/)' data.log | awk '{print $7}' | wc -l)
	if [ $countError -ne 0 ]; then
	errorAray+=("$i - $countError")
	
fi
done

#convert an array with \n
httpErrors=$(printf '%s\n' "${errorAray[@]}")


echo -e "Скрипт анализировал данные с $fromDate, выполнился за $SECONDS секунд\n\nТоп 10  IP адресов (с наибольшим кол-вом запросов):\n $ip\n\n Топ 10 запрашиваемых адресов:\n $url\n\n Все HTTP ошибки:\n $httpErrors\n\n Все HTTP коды:\n $httpCodes" | mail -s 'Логи для администратора за период с $fromDate'  admin@localhost.ru

rm -f "$lockfile"

trap - INT TERM EXIT










