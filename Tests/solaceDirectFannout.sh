#!/bin/bash

RUN_TIME_SEC=${1}
SOLACE_HOST=${2}
. "./utils.bash"

runSdkPerf ()
{
# Arguments are msgSize msgRate runSeconds clients
let "msgNum=${2}*${3}"
let "msgRate=${2}/${STREAM_COUNT}"
let "fanoutNum=${4}*${STREAM_COUNT}"
generateTopicList ${STREAM_COUNT}
echo ""
echo ""
echo "${1} Byte size test - ${2} ingress Msg/sec with fanount ${4} for ${3} seconds"
date +%F-%T
taskset -c 6,7,8,9,10 ${SDKPERF} -cip=${SOLACE_HOST} -stl=${topicList}\
 -cc=${fanoutNum} | grep -E '^Total.*rec|^Computed.rec' > /tmp/sdkperf &
sleep 3
resultPub=`taskset -c 1,2,3,4,5  ${SDKPERF} -cip=${SOLACE_HOST} -ptl=${topicList}\
 -mt=direct -cc=${STREAM_COUNT} -mrt=max -nagle\
 -msa=${1} -mr=${msgRate} -mn=${msgNum} ${DEBUG} | grep -E '^Total.*tran|^Computed.pub'`

killall -INT ${SDKPERF}
sleep 3
resultSub=`cat /tmp/sdkperf`
result=${resultPub}${resultSub}
echo $result
}

CLIENTS="1 2 5 10 50 100"
# 100 Bytes
msgSize=100
msgRate[1]=1500000
msgRate[2]=1100000
msgRate[5]=450000
msgRate[10]=250000
msgRate[50]=70000
msgRate[100]=40000

for clients in ${CLIENTS}
do
  runSdkPerf $msgSize ${msgRate[${clients}]} $RUN_TIME_SEC $clients
  evaluateResults $msgNum ${msgRate[${clients}]} $clients
done

# 1024 Bytes
msgSize=1024
msgRate[1]=760000
msgRate[2]=420000
msgRate[5]=220000
msgRate[10]=110000
msgRate[50]=22000
msgRate[100]=11000
for clients in ${CLIENTS}
do
  runSdkPerf $msgSize ${msgRate[${clients}]} $RUN_TIME_SEC $clients
  evaluateResults $msgNum ${msgRate[${clients}]} $clients
done

# 2048 Bytes
msgSize=2024
msgRate[1]=500000
msgRate[2]=500000
msgRate[5]=110000
msgRate[10]=55000
msgRate[50]=11000
msgRate[100]=5500
for clients in ${CLIENTS}
do
  runSdkPerf $msgSize ${msgRate[${clients}]} $RUN_TIME_SEC $clients
  evaluateResults $msgNum ${msgRate[${clients}]} $clients
done

date +%F-%T
