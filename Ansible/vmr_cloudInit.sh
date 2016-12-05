#!/bin/bash

passwd=PASSWORD
newPwd=`openssl passwd -1 ${passwd}`
newDay=`echo $(($(date --utc --date "$1" +%s)/86400))`
newPwd2=${newPwd//\//\\/}
mkdir /etc/solace/solace-container.d
touch /etc/solace/solace-container.d/shadow
echo "root:!!:16659:0:99999:7:::" >> /etc/solace/solace-container.d/shadow
echo "bin:!!:16659:0:99999:7:::" >> /etc/solace/solace-container.d/shadow
echo "daemon:!!:16659:0:99999:7:::" >> /etc/solace/solace-container.d/shadow
echo "adm:!!:16659:0:99999:7:::" >> /etc/solace/solace-container.d/shadow
echo "lp:!!:16659:0:99999:7:::" >> /etc/solace/solace-container.d/shadow
echo "sync:!!:16659:0:99999:7:::" >> /etc/solace/solace-container.d/shadow
echo "shutdown:!!:16659:0:99999:7:::" >> /etc/solace/solace-container.d/shadow
echo "halt:!!:16659:0:99999:7:::" >> /etc/solace/solace-container.d/shadow
echo "mail:!!:16659:0:99999:7:::" >> /etc/solace/solace-container.d/shadow
echo "operator:!!:16659:0:99999:7:::" >> /etc/solace/solace-container.d/shadow
echo "ftp:!!:16659:0:99999:7:::" >> /etc/solace/solace-container.d/shadow
echo "nobody:!!:16659:0:99999:7:::" >> /etc/solace/solace-container.d/shadow
echo "systemd-bus-proxy:!!:16659:0:99999:7:::" >> /etc/solace/solace-container.d/shadow
echo "systemd-network:!!:16659:0:99999:7:::" >> /etc/solace/solace-container.d/shadow
echo "dbus:!!:16659:0:99999:7:::" >> /etc/solace/solace-container.d/shadow
echo "rpc:!!:16659:0:99999:7:::" >> /etc/solace/solace-container.d/shadow
echo "ntp:!!:16659:0:99999:7:::" >> /etc/solace/solace-container.d/shadow
echo "tss:!!:16659:0:99999:7:::" >> /etc/solace/solace-container.d/shadow
echo "hacluster:!!:16659:0:99999:7:::" >> /etc/solace/solace-container.d/shadow
echo "rpcuser:!!:16659:0:99999:7:::" >> /etc/solace/solace-container.d/shadow
echo "nfsnobody:!!:16659:0:99999:7:::" >> /etc/solace/solace-container.d/shadow
echo "sshd:!!:16659:0:99999:7:::" >> /etc/solace/solace-container.d/shadow
echo "tcpdump:!!:16659:0:99999:7:::" >> /etc/solace/solace-container.d/shadow
echo "admin:!!:16659:0:99999:7:::" >> /etc/solace/solace-container.d/shadow
echo "support:!!:16659:0:99999:7:::" >> /etc/solace/solace-container.d/shadow
echo "nginx:!!:16659:0:99999:7:::" >> /etc/solace/solace-container.d/shadow
sed -i '/^admin:/s/!!:[0-9]*/'${newPwd2}':'${newDay}'/' /etc/solace/solace-container.d/shadow
chmod 000 /etc/solace/solace-container.d/shadow
