#!/bin/bash
iptables -F
iptables -A INPUT -p tcp –tcp-flags ALL NONE -j DROP
iptables -A INPUT -p tcp ! –syn -m state –state NEW -j DROP
iptables -A INPUT -p tcp –tcp-flags ALL ALL -j DROP
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -p tcp -m tcp –dport 80 -j ACCEPT
iptables -A INPUT -p tcp -m tcp –dport 443 -j ACCEPT
iptables -A INPUT -p tcp -m tcp –dport 3306 -j ACCEPT
iptables -A INPUT -p tcp -m tcp –dport 22 -j ACCEPT
iptables -A INPUT -p tcp -m tcp –dport 1935 -j ACCEPT
iptables -A INPUT -p tcp -m tcp –dport 8088 -j ACCEPT
iptables -A INPUT -p tcp -m tcp –dport 8086 -j ACCEPT
iptables -A INPUT -p tcp -m tcp –dport 8087 -j ACCEPT
iptables -A INPUT -p tcp -m tcp –dport 544 -j ACCEPT
iptables -A INPUT -p udp –match multiport –dports 6970:9999 -j ACCEPT
iptables -I INPUT -m state –state ESTABLISHED,RELATED -j ACCEPT
iptables -L -n
iptables-save | sudo tee /etc/sysconfig/iptables
service iptables restart
