#!/bin/bash

passwd=PASSWORD
newPwd=`openssl passwd -1 ${passwd}`
newDay=`echo $(($(date --utc --date "$1" +%s)/86400))`
newPwd2=${newPwd//\//\\/}
chmod 600 /etc/solace/solace-container.d/shadow
sed -i '/^admin:/s/!!:[0-9]*/'${newPwd2}':'${newDay}'/' /etc/solace/solace-container.d/shadow
chmod 000 /etc/solace/solace-container.d/shadow
