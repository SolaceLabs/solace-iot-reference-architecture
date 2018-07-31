#!/bin/bash -xe

core_vpn="default"
edge_vpn="default"
edge_name=`hostname -s`
edge_dns="localhost"
semp_port="8080"


while getopts "c:d:e:f:n:p:s:u:" opt; do
    case "$opt" in
    c)  core_vpn=$OPTARG
        ;;
    d)  core_dns=$OPTARG
        ;;
    e)  edge_vpn=$OPTARG
        ;;
    f)  edge_dns=$OPTARG
        ;;
    n)  edge_name=$OPTARG
        ;;
    p)  password=$OPTARG
        ;;
    s)  semp_port=$OPTARG
        ;;
    u)  username=$OPTARG
        ;;
    esac
done

shift $((OPTIND-1))
[ "$1" = "--" ] && shift

url="http://${edge_dns}:${semp_port}/SEMP/v2/config/msgVpns/${edge_vpn}/queues"
body="{\"queueName\":\"E2CQueue\",\"egressEnabled\":true,\"ingressEnabled\":true,\"permission\":\"delete\"}"
/tmp/sempv2_config_command.sh -n ${username} -p ${password} -u ${url} -d "${body}"

url="http://${edge_dns}:${semp_port}/SEMP/v2/config/msgVpns/${edge_vpn}/queues/E2CQueue/subscriptions"
body='{"subscriptionTopic":"out/*/svc1/>"}'
/tmp/sempv2_config_command.sh -n ${username} -p ${password} -u ${url} -d "${body}"