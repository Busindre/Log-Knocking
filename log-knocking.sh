#!/bin/bash

############## CONFIG ##############
port=7777
service_log="sshd.service"
payload="token1\|token2"
logfile=/var/log/proxy_knock.log
cron="1 minutes ago"
####################################

ips=$( journalctl  -u $service_log --since "$cron" | grep -i "from" |  grep -i "$payload" |  egrep -o '([0-9]{1,3}\.){3}[0-9]{1,3}' | sort | uniq | paste -d',' -s)

if [ -n "$ips" ]; then
        /usr/sbin/iptables -C INPUT -p tcp -s $ips --dport $port -j ACCEPT || (/usr/sbin/iptables -I INPUT -p tcp -s $ips --dport $port -j ACCEPT &&  echo "$(date "+%x %H:%M:%S") ip $ips added." >> $logfile)
fi
