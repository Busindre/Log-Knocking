# Log-Knocking
Simple shell script to open port to a specific ip address using "port knocking" based on a text string (Log-Knocking).

**Dependency**: journalctl (Systemd).

Example opening port 7777 in iptables for the IP connection that inserts the string "token1" or "token2" in the records of the ssh service. The script uses journaltcl, but it is trivial to adapt it.

Checking the ssh logins for those tokens will be done every minute using cron. Logs of the authenticated IPs will be saved in /var/log/proxy_knock.log

**Script log-knocking.sh**.
```bash
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
```

**Cronjob**.
```bash
# Run the script every minute.
*/1 * * * * /opt/log-knocking.sh
# (Optional) At 00:00 we close the access restarting the firewall and the clients will need to authenticate again.
00 * * * * systemctl restart iptables
```

**How could a client open port 7777 to its IP address?**.
```
# Simply using the user to enter the string "token1". In this way everything is encrypted.
ssh tocken1@domain.com

# telnet, netcat, etc (Not encrypted!)
telnet domain.com 22

Trying 95.156.229.190...
Connected to proxy.busindre.com.
Escape character is '^]'.
SSH-2.0-OpenSSH_6.6.1
tocken1
Protocol mismatch.
Connection closed by foreign host.
```

**Log example** (/var/log/proxy_knock.log)
```
04/30/17 21:42:10 ip 98.198.149.27,87.104.61.199 added.
04/30/17 22:12:55 ip 122.98.17.89 added.
```
