#!/usr/bin/env bash

titleHeader="%5s\t%6s\t%8s\t%6s\t%1s\n"
titleData="%5d\t%6s\t%8s\t%06s\t%1s\n"
printf "$titleHeader" "PID" "TTY" "STAT" "TIME" "COMMAND"

procDir='/proc'
pidList=$(ls -1 $procDir |  egrep "[0-9]{1,}"| sort -n )

for pid in $pidList
do
if [ -d "/proc/$pid" ]; then

tty=$(cat $procDir/$pid/stat |  awk '{print $7}')

if [ $tty -ne 0 ]; then
	tty=$tty
else
	tty="?"
fi

stat=$(cat $procDir/$pid/stat |  awk '{print $3}')
command=$(cat $procDir/$pid/cmdline)

if [ -z "$command" ]; then
	command="[`cat $procDir/$pid/comm`]"
else
	command=$command
fi

time=$(awk '{print $14+$15}' $procDir/$pid/stat)
time=$(( time / 100 ))

if ((time > 59)); then
	second=$(( time % 60 ))
	minute=$(( time / 60 ))
	time="$minute:$second"
else 
	if ((time < 10)); then 
		time="00:0$time"
	else 
		time="00:$time"
	fi	
fi

printf "$titleData" "$pid" "$tty" "$stat" "$time" "$command"

fi

done