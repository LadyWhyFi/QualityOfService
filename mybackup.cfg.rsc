# jun/15/2019 18:49:14 by RouterOS 6.42.10
# software id = 
#
#
#
/interface wireless security-profiles
set [ find default=yes ] supplicant-identity=MikroTik
/queue simple
add disabled=yes dst=ether1 max-limit=172k/172k name=queue1 target=ether2
/queue tree
add max-limit=172k name=Main_test_up parent=global priority=1 queue=default
add limit-at=10k max-limit=20k name=icmp_up packet-mark=icmp_up parent=\
    Main_test_up priority=1 queue=default
add limit-at=86k max-limit=172k name=rtp-voip_udp_15060_up packet-mark=\
    rtp-voip_udp_15060 parent=Main_test_up priority=3 queue=default
add limit-at=10k max-limit=20k name=sip_tcp_5060_up packet-mark=RCP-SIP-5060 \
    parent=Main_test_up priority=5 queue=default
add limit-at=20k max-limit=106k name=best_effort_25060 packet-mark=\
    UDP-BEST-EFFORT parent=Main_test_up queue=default
add limit-at=30k max-limit=172k name=rtp-voip_udp_15061_up packet-mark=\
    rtp-voip_udp_15061 parent=Main_test_up priority=3 queue=default
/ip address
add address=192.168.88.2/24 interface=ether1 network=192.168.88.0
add address=192.168.89.2/24 interface=ether2 network=192.168.89.0
/ip dhcp-client
add dhcp-options=hostname,clientid disabled=no interface=ether3
/ip dns
set servers=8.8.8.8,8.8.4.4
/ip firewall mangle
add action=mark-connection chain=prerouting comment=ICMP new-connection-mark=\
    ICMP_CONN passthrough=yes protocol=icmp
add action=mark-packet chain=prerouting comment=icmp_up_from_192.168.89.0/24 \
    connection-mark=ICMP_CONN new-packet-mark=icmp_up passthrough=no \
    src-address=192.168.89.0/24
add action=mark-connection chain=prerouting comment=UDP-RTP-VOIP dscp=0 \
    dst-port=15060 new-connection-mark=UDP-RTP-VOIP passthrough=yes protocol=\
    udp
add action=mark-packet chain=prerouting comment=udp_rtp-voip_up \
    connection-mark=UDP-RTP-VOIP dscp=46 new-packet-mark=rtp-voip_udp_15060 \
    passthrough=no src-address=192.168.89.0/24
add action=mark-connection chain=prerouting comment=TCP-SIP dst-port=5060 \
    new-connection-mark=TCP-SIP passthrough=yes protocol=tcp
add action=mark-packet chain=prerouting comment=tcp-sip-up connection-mark=\
    TCP-SIP dscp=26 new-packet-mark=RCP-SIP-5060 passthrough=yes src-address=\
    192.168.89.0/24
add action=mark-connection chain=prerouting comment=UDP-BEST-EFFORT dst-port=\
    25060 new-connection-mark=UDP-BEST-EFFORT passthrough=yes protocol=udp
add action=mark-packet chain=prerouting comment=udp-best-effort-up \
    new-packet-mark=UDP-BEST-EFFORT_25060 passthrough=no src-address=\
    192.168.89.0/24
add action=mark-connection chain=prerouting comment=UDP-RTP-VOIP-8K dst-port=\
    15061 new-connection-mark=UDP-RTP-VOIP_8K passthrough=yes protocol=udp
add action=mark-packet chain=prerouting comment=udp-trp-voip-8k_up \
    connection-mark=UDP_TRP_VOIP_8K dscp=46 new-packet-mark=\
    rtp-voip_udp_15061 passthrough=no src-address=192.168.89.0/24
/ip firewall nat
add action=masquerade chain=srcnat disabled=yes out-interface=ether3
/ip route
add distance=1 dst-address=192.168.88.2/32 gateway=ether2 pref-src=\
    192.168.89.1
add distance=1 dst-address=192.168.89.2/32 gateway=ether3 pref-src=\
    192.168.88.1
/system identity
set name=BR750
