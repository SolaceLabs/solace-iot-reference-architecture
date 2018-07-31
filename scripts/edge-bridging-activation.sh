#!/bin/bash -xe

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

sleep 60

/tmp/edge-bridge-configure.sh -u ${username} -p ${password} -d ${core_dns}
/tmp/edge-queue-configure.sh -u ${username} -p ${password} -d ${core_dns}
/tmp/core-bridge-configure.sh -u ${username} -p ${password} -d ${core_dns}
/tmp/core-queue-configure.sh -u ${username} -p ${password} -d ${core_dns}