#!/usr/bin/env bash

BUILDRUN=build-$(date +%y%m%d%H%M%s).log

printmsg(){
printf "\t\e[34m%s\e[0m:\t\t\e[31m%s\e[0m\n" "$1" "$2"
}

printhdr(){
printf "\n\e[33m\e[1m%s\e[0m\n" "$1"
}

progress(){
	local -r pid="${1}"
	tput sc
	while ps a | awk '{print $1}' | grep -q "${pid}"; do
		printf "%s" $(cat ${BUILDRUN} | grep Step | tail -n1)
		sleep 0.5
		tput el1
		tput rc
	done
	tail -n5 ${BUILDRUN}
}
