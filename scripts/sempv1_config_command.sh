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

while [ $count -lt $retries  ]; do
    query_response=`curl -u ${name}:${password} ${url} -d "${data}"`
    query_response_code=`echo $query_response | xmllint -xpath 'string(/rpc-reply/execute-result/@code)' -`
    if [[ -z ${query_response_code} && ${query_response_code} != "ok" ]]; then
        ((count++))
        echo "`date` WARN:${script_name}: SEMPv1 command attempt ${count} of ${retries} failed -${query_response}-" >&2
        sleep ${wait}
    else
        echo "`date` INFO:${script_name}: SEMPv1 command passed -${query_response}-" >&2
        exit 0
    fi
done
echo "`date` ERROR:${script_name}: SEMPv1 command failed -${query_response}-" >&2
exit 1