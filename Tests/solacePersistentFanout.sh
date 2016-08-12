#!/bin/bash

RUN_TIME_SEC=${1}
SOLACE_HOST=${2}

. "./utils.bash"

STREAM_COUNT=1

runSdkPerf ()
{
  # Arguments are msgSize msgRate runSeconds fanout
  let "msgNum=${2}*${3}"
  let "msgRate=${2}/${STREAM_COUNT}"
  generateTopicList ${STREAM_COUNT}
  generateQueueList ${4}
  echo ""
  echo "${1} Byte size test - ${4} fannout ${2} Msg/sec for ${3} seconds"
  date +%F-%T
  taskset -c 6,7,8,9,10 ${SDKPERF} -cip=${SOLACE_HOST} -sql=${queueList} -stl=${topicList}\
   -pe -cc=${4} | grep -E '^Total.*rec|^Computed.rec' > /tmp/sdkperf &
  sleep 5
  resultPub=`taskset -c 1,2,3,4,5  ${SDKPERF} -cip=${SOLACE_HOST} -ptl=${topicList}\
   -mt=persistent -cc=${STREAM_COUNT} -mrt=max -nagle\
   -msa=${1} -mr=${msgRate} -mn=${msgNum} ${DEBUG} | grep -E '^Total.*tran|^Computed.pub'`

killall -INT ${SDKPERF}
sleep 3
resultSub=`cat /tmp/sdkperf`
result=${resultPub}${resultSub}
echo $result


}

rate[1]=45000
rate[2]=41000
rate[5]=37000
rate[10]=30000
rate[50]=12000

for size in 1024 2048
do
  for clients in 1 2 5 10 50
  do
    runSdkPerf $size ${rate[${clients}]} $RUN_TIME_SEC $clients 
    evaluateResults $msgNum ${rate[${clients}]} $clients
  done
done

rate[1]=20000
rate[2]=18000
rate[5]=12000
rate[10]=6000
rate[50]=1500
size=20480
for clients in 1 2 5 10 50
do
  runSdkPerf $size ${rate[${clients}]} $RUN_TIME_SEC $clients
  evaluateResults $msgNum ${rate[${clients}]} $clients
done

date +%F-%T
