#!/bin/bash
result=`curl -u admin:adminadmin http://localhost:8080/SEMP -d '<rpc semp-version="soltr/8_11VMR"><show><message-vpn><vpn-name>*</vpn-name></message-vpn></show></rpc>'`
connection_count=`echo $result | xmllint -xpath "string(/rpc-reply/rpc/show/message-vpn/vpn/connections)" -`
echo "{\"time\":\"`date`\",\"host\":\"`hostname -s`\",\"count\":${connection_count}}" >> /var/log/connection_count.log