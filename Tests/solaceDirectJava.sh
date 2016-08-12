#!/bin/bash
RUN_TIME_SEC=${1}
SOLACE_HOST=${2}
TEST_TYPE=${3}

. "./utils.bash"
. "./rateTableSolace.bash"


runSdkPerf ()
{
# Arguments are msgSize msgRate runSeconds 
let "msgNum=${2}*${3}"
let "msgRate=${2}/${STREAM_COUNT}"
generateTopicList ${STREAM_COUNT}
echo ""
echo ""
echo "${1} Byte size test - ${2} Msg/sec for ${3} seconds"
date +%F-%T

taskset -c 1,2,3 nice -n 10 ${SDKPERF_HOME}/${SDKPERF} -cip=${SOLACE_HOST} -q -cc=${STREAM_COUNT} -jcf=cf\
 -stl=${topicList} -sri=100 -cor |  grep -E '^Total.*rec|^Computed subscriber rate' > /tmp/sdkperf &

sleep 5

resultPub=`taskset -c 1,2,3 nice -n -10 ${SDKPERF_HOME}/${SDKPERF} -cip=${SOLACE_HOST} -q -cc=${STREAM_COUNT} -cpc -jcf=cf\
 -ptl=${topicList} -mt=direct -msa=${1} -mr=${msgRate} -mn=${msgNum} -mrt=max\
 | grep -E '^Total.*tran|^Computed.pub'`

killall -TERM java
sleep 5 
resultSub=`cat /tmp/sdkperf`
result=${resultPub}${resultSub}

}


for size in ${SIZES}
do
  runSdkPerf ${size} ${rate[${size}]} $RUN_TIME_SEC ${SOLACE_HOST}
  evaluateResults $msgNum ${rate[${size}]}  
done
date +%F-%T
