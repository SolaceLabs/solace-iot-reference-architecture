#!/bin/bash

retries=10
wait=20

while getopts "d:n:p:r:u:w:" opt; do
    case "$opt" in
    d)  data=$OPTARG
        ;;
    n)  name=$OPTARG
        ;;
    p)  password=$OPTARG
        ;;
    r)  retries=$OPTARG
        ;;
    u)  url=$OPTARG
        ;;
    w)  wait=$OPTARG
        ;;
    esac
done

shift $((OPTIND-1))
[ "$1" = "--" ] && shift

count="0"
header="Content-Type: application/json"
method="POST"

while [ $count -lt $retries  ]; do
    query_response_code=""
    query_response=`curl -H "${header}" -X ${method} -u ${name}:${password} ${url} -d "${data}"`
    query_response_code=`echo $query_response | grep -oE "\"responseCode\":[0-9]+" | grep -oE "[0-9]+"`
    if [[ -z ${query_response_code} && ${query_response_code} != "200" ]]; then
        ((count++))
        echo "`date` WARN:${script_name}: SEMPv2 command attempt ${count} of ${retries} failed -${query_response}-" >&2
        sleep ${wait}
    else
        echo "`date` INFO:${script_name}: SEMPv2 command passed -${query_response}-" >&2
        exit 0
    fi
done
echo "`date` ERROR:${script_name}: SEMPv2 command failed -${query_response}-" >&2
exit 1