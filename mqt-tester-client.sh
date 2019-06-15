#!/bin/bash
: <<README
=======================================================================
mqt-tester-client is a simple traffic generator to demonstrate
Mikrotik HTB Queue Tree QoS technology.
Do not hesitate to improve this script if required.

mqt-tester-client uses iperf, netcat and ping tools

author:		bruno.on.the.road@gmail.com & Roussel Y.
date:		15/06/2019
version:	0.2.3

Works on:	Ubuntu 10.04, 12.04 and 14.04 LTS Desktop
			iperf 2.0.4
			netcat-openbsd 1.89-3ubuntu2
			
Requires:	On distant end : mqt-tester-server-with-tmux.sh OR mqt-tester-server.sh
			sip_pusher.sh
			sip_msg_invite
			sip_msg_ack
			sip_msg_bye
			and of course a Mikrotik (RB750) router

In order to simulate SIP traffic, I have decided to use the
RFC 3665 SIP Basic Call Flow Examples.  These messages are
pushed (in one direction only though) using the netcat tool. 

Prior running script, ensure routing on mikrotik router(s) and computers
are established. 
e.g. route add -net 192.168.88.0 netmask 255.255.255.0 gw 192.168.89.1

Prior running script, start mqt-tester-server.sh on distant end.
This script will launch:
iperf -s -p [15060|25060] -u -l [172|1250]
netcat -lk 5060

==========================="FLOW OVERVIEW"============================

				DSCP	HTB PRIO	PAYLOAD			UDP/TCP
SIP			26		5			+/- 1000	5060
RTP-VOIP		46		3			172 (RTP+G711)	15060
RTP-VOIP-8k		46		3			32 (TRP+G729A) 	15061
BEST EFFORT		0		8			1250		25060
----
ICMP					1			972 (+8 ICMP O/H) 

=======================================================================
README
#
#Initialisation number of test cycles
TEST_CYCLE=1
#
#FIND IPERF COMMAND EXECUTABLE
IPERF=$(which iperf)
#
#IPERF REPORT INTERVAL
REPORT_INT=15
#
#IP Addresses variables
IP_DESTINATION=192.168.88.9
#
#TOS/DSCP variables
DSCP_BE="0x00"
DSCP_AF31="0x68" #SIP	
DSCP_EF="0xb8" #RTP VOIP
#
#Timing variables
DURATION_BEST_EFFORT=120
DURATION_RTP_VOIP=60
DURATION_RTP_VOIP_8K=60
DURATION_ICMP=15
#
#UDP variables
UDP_SIP=5060
UDP_RTP_VOIP=15060
UDP_RTP_VOIP_8K=15061
UDP_BEST_EFFORT=25060
#
#payload lenght variables
PAYLOAD_BEST_EFFORT=1250
PAYLOAD_RTP_VOIP=172
PAYLOAD_RTP_VOIP_8K=32
PAYLOAD_ICMP=972
#
#ICMP variables
PING_COUNT=30
PING_INTERVAL=0.5
#
#protocol overhead definitions
OH_UDP=8
OH_IP=20
OH_ETH=18 # 14 HEADER, 4 CRC, PREAMBLE BYTES (8) ARE IGNORED
OH_ICMP=8
#
#iperf UDP Target Bandwidth=payload * pps * 8 bits
BW_RTP_VOIP=$(( $PAYLOAD_RTP_VOIP * 50 * 8 ))
BW_RTP_VOIP_8K=$(( $PAYLOAD_RTP_VOIP_8K * 50 * 8 ))
BW_BEST_EFFORT=$(( $PAYLOAD_BEST_EFFORT * 10 * 8 ))
BW_ICMP=$(( $PAYLOAD_ICMP * 2 * 8 ))
#
#Bits 0n The Wire (BOTW)
#BOTW = (payload + all protocol overhead) * pps * 8 bits
BOTW_RTP_VOIP=$(( (${PAYLOAD_RTP_VOIP} + ${OH_UDP} + ${OH_IP} + ${OH_ETH}) * 50 * 8 ))
BOTW_RTP_VOIP_8K=$(( (${PAYLOAD_RTP_VOIP_8K} + ${OH_UDP} + ${OH_IP} + ${OH_ETH}) * 50 * 8 ))
BOTW_BEST_EFFORT=$(( (${PAYLOAD_BEST_EFFORT} + ${OH_UDP} + ${OH_IP} + ${OH_ETH}) * 10 * 8 ))
BOTW_ICMP=$(( (${PAYLOAD_ICMP} + ${OH_ICMP} + ${OH_IP} + ${OH_ETH}) * 2 * 8  ))
#
clear
echo "========== MIKROTIK QUEUE TREE TESTER =========="
echo "Bits On The Wire RTP VOIP: ${BOTW_RTP_VOIP} bps"
echo "Bits on The Wire RTP VOIP 8K: ${BOTW_RTP_VOIP_8K} bps"
echo "Bits On The Wire BEST EFFORT: ${BOTW_BEST_EFFORT} bps"
echo "Bits On The Wire ICMP: ${BOTW_ICMP} bps"
#
while [ true ]; do
	
	echo "=========="
	
	echo "TEST CYCLE: ${TEST_CYCLE}"

	
		${IPERF} -c ${IP_DESTINATION} -p ${UDP_BEST_EFFORT} \
		--udp --bandwidth ${BW_BEST_EFFORT} --len ${PAYLOAD_BEST_EFFORT} \
		--interval ${REPORT_INT} --time ${DURATION_BEST_EFFORT} --parallel 1 \
		--tos ${DSCP_BE} &
	
	echo "TXing BEST_EFFORT traffic started ... HTB PRIO 8"
	
	sleep 30
	

		sip_pusher.sh sip_msg_invite ${IP_DESTINATION} ${UDP_SIP} ${DSCP_AF31} &
	
	echo "SIP_INVITE MSG sent ... HTB PRIO 5"
	
	
		sip_pusher.sh sip_msg_ack ${IP_DESTINATION} ${UDP_SIP} ${DSCP_AF31} &
	
	echo "SIP_ACK MSG sent ... HTB PRIO 5"
	

		${IPERF} -c ${IP_DESTINATION} -p ${UDP_RTP_VOIP} \
		--udp --bandwidth ${BW_RTP_VOIP} --len ${PAYLOAD_RTP_VOIP} \
		--interval ${REPORT_INT} --time ${DURATION_RTP_VOIP} --parallel 1 \
		--tos ${DSCP_EF} &
	
	echo "TXing RTP_VOIP traffic started ... HTB PRIO 3"

	sleep 15
		sip_pusher.sh sip_msg_invite ${IP_DESTINATION} ${UDP_SIP} ${DSCP_AF31} &

	echo "SIP_INVITE MSG send ...HTB PRIO 5"

		sip_pusher.sh sip_msg_ack ${IP_DESTINATION} ${UDP_SIP} ${DSCP_AF31} &

	echo "SIP_ACK MSG send ... HTB prio 5"
		
		${IPERF} -c ${IP_DESTINATION} -p ${UDP_RTP_VOIP_8K} \
		--udp --bandwidth ${BW_RTP_VOIP_8K} --len ${PAYLOAD_RTP_VOIP_8K} \
		--interval ${REPORT_INT} --time ${DURATION_RTP_VOIP_8K} --parallel 1 \
		--tos ${DSCP_EF} &

	echo "TXing RTP_VOIP traffic started ... HTB PRIO 3"

	sleep 15
	
	
		ping ${IP_DESTINATION} -n -c ${PING_COUNT} \
		-s ${PAYLOAD_ICMP} -i ${PING_INTERVAL} &
	
	echo "TXing ICMP traffic started ... HTB PRIO 1"
	
	sleep 30
	
	
		sip_pusher.sh sip_msg_bye ${IP_DESTINATION} ${UDP_SIP} ${DSCP_AF31} &
	
	echo "SIP_BYE MSG sent ... HTB PRIO 5"

	sleep 15
		sip_pusher.sh sip_msg_bye ${IP_DESTINATION} ${UDP_SIP} ${DSCP_AF31} &
	
	echo "SIP_BYE MSG sent ... HTB PRIO 5"
	
	#allow 15 + 5 extra seconds to empty the queues
	sleep 20
	
	#wait ?? to be investigated
	
	(( TEST_CYCLE++ ))

done

exit 0
