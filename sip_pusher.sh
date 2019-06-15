#!/bin/bash
#author: bruno.on.the.road@gmail.com
# script sends mesage and terminates with emulated Ctrl-C
#netcat server setting: nc -lk portnumber 
NC=$(which netcat)
MSG=$1
DEST=$2
PORT=$3
DSCP=$4
cat ${MSG} | ${NC} ${DEST} ${PORT} -T ${DSCP} &
#NETCATPID=$!
#echo $NETCATPID
#sleep 1
#kill -s TERM $NETCATPID
exit 0
