#!/bin/bash
RUN_TIME_SEC=${1}
SOLACE_CORE=${2}
SOLACE_EDGE=${3}
TEST_TYPE=${4}

if [ -z "${4}" ]
then
   echo "USAGE: ${0} <runTime> <SolaceCoreHost> <SolaceEdgeHost> [solaceDirectIoT10|solaceDirectIoT100]"
   exit 1
fi

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

${SDKPERF_HOME}/${SDKPERF_JAVA} -cip=${SOLACE_CORE} -q  -jcf=cf \
 -sql="CoreQueue" -sri=100 -cor |  grep -E '^Total.*rec|^Computed subscriber rate' > /tmp/sdkperf &

sleep 5

resultPub=`${SDKPERF_HOME}/${SDKPERF_MQTT} -cip=${SOLACE_EDGE} -cc=${STREAM_COUNT} -q \
 -ptl=${topicList} -mpq=0 -msa=${1} -mr=${msgRate} -mn=${msgNum} -mrt=max\
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

