#!/bin/bash
: <<README
=======================================================================
mqt-tester-server-with-tmux works together with mqt-tester-client
mqt-tester-client is a simple traffic generator to get familiar with Mikrotik 
HTB Queue Tree QoS

author:		bruno.on.the.road@gmail.com
date:		20-05-2017
version:	0.3.0

Working on:	Ubuntu 14.04 LTS Desktop

Working with:	iperf 2.0.4
				netcat-openbsd 1.89-3ubuntu2
				tmux 1.8-5
			
Requires on distant end:	mqt-tester-client.sh 
							sip_pusher.sh 
							sip_msg_invite
							sip_msg_ack
							sip_msg_bye		
			
Prior running script, ensure routing on mikrotik routers is established
e.g. route add -net 192.168.89.0 netmask 255.255.255.0 gw 192.168.88.1			
=======================================================================
README
#
#FIND COMMAND EXECUTABLES
IPERF=$(which iperf)
NC=$(which netcat)
TMUX=$(which tmux)
#
#UDP variables
UDP_SIP=5060
UDP_RTP_VOIP=15060  	#G711 codec
UDP_RTP_VOIP_8K=15061  	#G729A codec
UDP_BEST_EFFORT=25060
#
#payload lenght variables
PAYLOAD_BEST_EFFORT=1250
PAYLOAD_RTP_VOIP=172
PAYLOAD_RTP_VOIP_8K=32
#
SESSION="mqt"

${TMUX} -2 new-session -d -s $SESSION

${TMUX} new-window -t $SESSION:1 -n 'mqt'
${TMUX} split-window -h
${TMUX} select-pane -t 0
${TMUX} send-keys "${IPERF} -s -p ${UDP_RTP_VOIP} -u -l ${PAYLOAD_RTP_VOIP}" C-m
${TMUX} select-pane -t 1
${TMUX} send-keys "${IPERF} -s -p ${UDP_BEST_EFFORT} -u -l ${PAYLOAD_BEST_EFFORT}" C-m
${TMUX} split-window -v
${TMUX} send-keys "${IPERF} -s -p ${UDP_RTP_VOIP_8K} -u -l ${PAYLOAD_RTP_VOIP_8K}" C-m
${TMUX} select-pane -t 0
${TMUX} split-window -v
${TMUX} send-keys "${NC} -lk ${UDP_SIP}" C-m

${TMUX} -2 attach-session -t $SESSION




