#!/bin/bash -xe

core_vpn="default"
edge_vpn="default"
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

sleep 15

service network restart

sleep 10

url="http://${core_dns}:${semp_port}/SEMP"

body="<rpc semp-version='soltr/8_10VMR'><ip><vrf><name>management</name><interface><ip-interface>intf0:1</ip-interface><shutdown/></interface></vrf></ip></rpc>"
/tmp/sempv1_config_command.sh -n ${username} -p ${password} -u ${url} -d "${body}"

body="<rpc semp-version='soltr/8_10VMR'><interface><phy-interface>intf0</phy-interface><os-physical-interface><os-physical-interface-name>eth1</os-physical-interface-name></os-physical-interface></interface></rpc>"
/tmp/sempv1_config_command.sh -n ${username} -p ${password} -u ${url} -d "${body}"

body="<rpc semp-version='soltr/8_10VMR'><ip><vrf><name>management</name><interface><ip-interface>intf0:1</ip-interface><no><shutdown/></no></interface></vrf></ip></rpc>"
/tmp/sempv1_config_command.sh -n ${username} -p ${password} -u ${url} -d "${body}"
