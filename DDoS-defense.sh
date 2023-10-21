#!/bin/bash
# Title: Cardano Stakepool iptables DDoS Defense Script
# Description: This script configures and deploys iptables rules designed to safeguard a Cardano Stakepool from a range of DDoS attack vectors, ensuring rule persistence across reboots
# Author: Carden Pool [CRPL] - www.cardenpool.com
# Date: October 21, 2023

# IMPORTANT: Before use, please update the value within the angle brackets <YOUR-VALUE> for all the fields. Save the file and grant execution rights (chmod +x DDoS-defense.sh)
#
# 	  Notes: If manually run, to execute this script with root priviledges (sudo antiDDoS.sh)
#		         To make customization easier, this files makes use of Prometheus and Grafana port number suggested by the CoinCashew node setup guide


# 0: Limit node port, IOHK and NTP connections
# -----------------------> REPLACE THE PLACEHOLDER WITH YOUR CARDANO INSTANCE TCP PORT
# Node instance
/sbin/iptables -I INPUT -p tcp -m tcp --dport <YOUR-PORT-HERE> --tcp-flags FIN,SYN,RST,ACK SYN -m connlimit --connlimit-above 5 --connlimit-mask 32 --connlimit-saddr -j REJECT --reject-with tcp-reset
# Grafana
# -----------------------> NOTE: Useful only on machine running Grafana
#/sbin/iptables -I INPUT -p tcp -m tcp --dport 3000 --tcp-flags FIN,SYN,RST,ACK SYN -m connlimit --connlimit-above 5 --connlimit-mask 32 --connlimit-saddr -j REJECT --reject-with tcp-reset
# Chrony
/sbin/iptables -A INPUT -p udp --dport 123 -m limit --limit 10/s --limit-burst 20 -j ACCEPT
/sbin/iptables -A INPUT -p udp --dport 123 -j DROP
/sbin/iptables -A INPUT -p udp --dport 123 -m recent --name ntp-flood --set
/sbin/iptables -A INPUT -p udp --dport 123 -m recent --name ntp-flood --rcheck --seconds 60 --hitcount 60 -j DROP
# Prometheus
# -----------------------> NOTE: Useful only on machine without Grafana
/sbin/iptables -A INPUT -p udp --dport 9100 -m limit --limit 10/s --limit-burst 20 -j ACCEPT
/sbin/iptables -A INPUT -p udp --dport 9100 -j DROP
/sbin/iptables -A INPUT -p udp --dport 9100 -m recent --name ntp-flood --set
/sbin/iptables -A INPUT -p udp --dport 9100 -m recent --name ntp-flood --rcheck --seconds 60 --hitcount 60 -j DROP
# Prometheus metric data
# -----------------------> NOTE: Useful only on machine without Grafana
# -----------------------> REPLACE THE PLACEHOLDER WITH YOUR PROMETHEUS METRIC DATA PORT
/sbin/iptables -A INPUT -p udp --dport 12798 -m limit --limit 10/s --limit-burst 20 -j ACCEPT
/sbin/iptables -A INPUT -p udp --dport 12798 -j DROP
/sbin/iptables -A INPUT -p udp --dport 12798 -m recent --name ntp-flood --set
/sbin/iptables -A INPUT -p udp --dport 12798 -m recent --name ntp-flood --rcheck --seconds 60 --hitcount 60 -j DROP

### 1: Drop invalid packets ###
# Prevents: Prevents handling of packets with invalid connection tracking states.
# Explanation: Drops packets with INVALID connection tracking states, which can indicate malformed or unauthorized packets.
/sbin/iptables -t mangle -A PREROUTING -m conntrack --ctstate INVALID -j DROP

### 2: Drop TCP packets that are new and are not SYN ###
# Prevents: Prevents SYN flood attacks.
# Explanation: Drops non-SYN TCP packets in NEW connection state, mitigating SYN flood attacks by allowing only valid connection establishment attempts.
/sbin/iptables -t mangle -A PREROUTING -p tcp ! --syn -m conntrack --ctstate NEW -j DROP
#/sbin/iptables -A INPUT -p tcp --syn -m connlimit --connlimit-above 10 -j DROP

### 3: Drop SYN packets with suspicious MSS value ###
# Prevents: Prevents certain types of SYN flood attacks.
# Explanation: Drops SYN packets with abnormal TCP Maximum Segment Size (MSS), which helps in mitigating specific SYN flood attacks.
/sbin/iptables -t mangle -A PREROUTING -p tcp -m conntrack --ctstate NEW -m tcpmss ! --mss 536:65535 -j DROP

### 4: Block packets with bogus TCP flags ###
# Prevents: Prevents TCP-based attacks that manipulate TCP flags.
# Explanation: Drops packets with suspicious combinations of TCP flags, protecting against SYN/ACK floods, Xmas scans, NULL scans, and similar attacks.
/sbin/iptables -t mangle -A PREROUTING -p tcp --tcp-flags FIN,SYN,RST,PSH,ACK,URG NONE -j DROP
/sbin/iptables -t mangle -A PREROUTING -p tcp --tcp-flags FIN,SYN FIN,SYN -j DROP
/sbin/iptables -t mangle -A PREROUTING -p tcp --tcp-flags SYN,RST SYN,RST -j DROP
/sbin/iptables -t mangle -A PREROUTING -p tcp --tcp-flags SYN,FIN SYN,FIN -j DROP
/sbin/iptables -t mangle -A PREROUTING -p tcp --tcp-flags FIN,RST FIN,RST -j DROP
/sbin/iptables -t mangle -A PREROUTING -p tcp --tcp-flags FIN,ACK FIN -j DROP
/sbin/iptables -t mangle -A PREROUTING -p tcp --tcp-flags ACK,URG URG -j DROP
/sbin/iptables -t mangle -A PREROUTING -p tcp --tcp-flags ACK,FIN FIN -j DROP
/sbin/iptables -t mangle -A PREROUTING -p tcp --tcp-flags ACK,PSH PSH -j DROP
/sbin/iptables -t mangle -A PREROUTING -p tcp --tcp-flags ALL ALL -j DROP
/sbin/iptables -t mangle -A PREROUTING -p tcp --tcp-flags ALL NONE -j DROP
/sbin/iptables -t mangle -A PREROUTING -p tcp --tcp-flags ALL FIN,PSH,URG -j DROP
/sbin/iptables -t mangle -A PREROUTING -p tcp --tcp-flags ALL SYN,FIN,PSH,URG -j DROP
/sbin/iptables -t mangle -A PREROUTING -p tcp --tcp-flags ALL SYN,RST,ACK,FIN,URG -j DROP

### 5: Block spoofed packets ###
# A series of rules that drop packets with spoofed source IP addresses.
# Prevents: Prevents IP spoofing and certain reflection attacks.
# Explanation: Drops packets with reserved or invalid source IP addresses, thwarting IP spoofing and reflection attacks.
/sbin/iptables -t mangle -A PREROUTING -s 224.0.0.0/3 -j DROP
/sbin/iptables -t mangle -A PREROUTING -s 169.254.0.0/16 -j DROP
/sbin/iptables -t mangle -A PREROUTING -s 172.16.0.0/12 -j DROP
/sbin/iptables -t mangle -A PREROUTING -s 192.0.2.0/24 -j DROP
/sbin/iptables -t mangle -A PREROUTING -s 10.0.0.0/8 -j DROP
/sbin/iptables -t mangle -A PREROUTING -s 240.0.0.0/5 -j DROP
# ATTENTION: These subnets can be used in some node configs! Comment if something stop to work after run these rules 
/sbin/iptables -t mangle -A PREROUTING -s 0.0.0.0/8 -j DROP
/sbin/iptables -t mangle -A PREROUTING -s 127.0.0.0/8 ! -i lo -j DROP
#/sbin/iptables -t mangle -A PREROUTING -s 192.168.0.0/16 -j DROP

### 6: Drop ICMP (you usually don't need this protocol) ###
# Prevents: Mitigates potential ICMP-based attacks.
# Explanation: Drops ICMP (ping) packets, which could be exploited in certain attacks or used for network reconnaissance.
/sbin/iptables -t mangle -A PREROUTING -p icmp -j DROP

### 7: Drop fragments in all chains ###
# Prevents: Prevents fragmentation-based attacks.
# Explanation: Drops fragmented packets, guarding against fragmentation attacks that attempt to evade security measures.
/sbin/iptables -t mangle -A PREROUTING -f -j DROP

### 8: Limit connections per source IP ###
# Prevents: Prevents connection-based attacks.
# Explanation: Rejects new incoming TCP connections if the count from a source IP exceeds 111, countering connection-based attacks like SYN floods.
/sbin/iptables -A INPUT -p tcp -m connlimit --connlimit-above 111 -j REJECT --reject-with tcp-reset

### 9: Limit RST packets ###
# A series of rules that limit and drop incoming RST (reset) packets.
# Prevents: Mitigates TCP reset-based attacks.
# Explanation: Limits and drops incoming TCP RST packets, deterring certain TCP reset attacks.
/sbin/iptables -A INPUT -p tcp --tcp-flags RST RST -m limit --limit 2/s --limit-burst 2 -j ACCEPT
/sbin/iptables -A INPUT -p tcp --tcp-flags RST RST -j DROP

### 10: Limit new TCP connections per second per source IP ###
# A series of rules that limit and drop new TCP connections.
# Prevents: Prevents connection-based attacks.
# Explanation: Limits the rate of new incoming TCP connections from a single source IP, reducing the risk of SYN flood attacks.
/sbin/iptables -A INPUT -p tcp -m conntrack --ctstate NEW -m limit --limit 60/s --limit-burst 20 -j ACCEPT
/sbin/iptables -A INPUT -p tcp -m conntrack --ctstate NEW -j DROP

### 11: Use SYNPROXY on all ports (disables connection limiting rule) ###
# Note: These rules are commented out to disable them.
# Explanation: These rules are related to using SYNPROXY to handle SYN flood attacks on all ports. The existing connection limiting rule (#8) is disabled when using SYNPROXY.
#/sbin/iptables -t raw -A PREROUTING -p tcp -m tcp --syn -j CT --notrack
#/sbin/iptables -A INPUT -p tcp -m tcp -m conntrack --ctstate INVALID,UNTRACKED -j SYNPROXY --sack-perm --timestamp --wscale 7 --mss 1460
#/sbin/iptables -A INPUT -m conntrack --ctstate INVALID -j DROP

### 12: SSH brute-force protection ###
# -----------------------> REPLACE THE PLACEHOLDER WITH YOUR SSH PORT
# Prevents: Prevents SSH brute-force attacks.
/sbin/iptables -A INPUT -p tcp --dport <YOUR-SSH-PORT-HERE> -m state --state NEW -m recent --set --name SSH
/sbin/iptables -A INPUT -p tcp --dport <YOUR-SSH-PORT-HERE> -m state --state NEW -m recent --update --seconds 120 --hitcount 8 --rttl --name SSH -j DROP
/sbin/iptables -A INPUT -p tcp --dport <YOUR-SSH-PORT-HERE> -m state --state NEW -j ACCEPT

### 13: Protection against port scanning ###
# Prevents: Prevents port scanning attempts.
# Explanation: Sets up rules to limit and block incoming packets indicative of port scanning, helping detect and prevent reconnaissance activities.
/sbin/iptables -N port-scanning
/sbin/iptables -A port-scanning -p tcp --tcp-flags SYN,ACK,FIN,RST RST -m limit --limit 1/s --limit-burst 2 -j RETURN
/sbin/iptables -A port-scanning -j DROP

### 14: Web services ###
# -----------------------> NOTE: Useful only on machine running Grafana
# A series of rules that allow incoming traffic for common web services.
# Explanation: Allows incoming traffic on ports 80 (HTTP), 443 (HTTPS), and 8088 (assumed web service port) for normal web service functioning.
#sudo /sbin/iptables -A INPUT -p tcp --dport 80 -m state --state NEW -j ACCEPT
#sudo /sbin/iptables -A INPUT -p tcp --dport 443 -m state --state NEW -j ACCEPT
