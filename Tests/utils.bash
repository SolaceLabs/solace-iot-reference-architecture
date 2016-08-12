HA_HOME=/root/kbarr/HA_Testing
SDKPERF=sdkperf_c_d36
if [ -z ${TOPIC_PREFIX} ]
then
  TOPIC_PREFIX=T.TEST.
fi
QUEUE_PREFIX=Q.TEST.

#DEBUG="2> /dev/null"
DEBUG=""
RED=`tput setaf 1`
GREEN=`tput setaf 2`
BOLD=`tput bold`
RESET=`tput sgr0`

generateTopicList()
{
  topicList=${TOPIC_PREFIX}1
  for i in `seq 2 ${1}`
  do
    topicList="${topicList},${TOPIC_PREFIX}${i}"
  done
}

generateQueueList()
{
  queueList=${QUEUE_PREFIX}1
  for i in `seq 2 ${1}`
  do
    queueList="${queueList},${QUEUE_PREFIX}${i}"
  done
}

evaluateResults()
{
  expectedMsgs="${1}"
  expectedRate="${2}"
  if [ -z "${3}" ]
  then
    fanout=1
  else
    fanout=${3}
  fi
  transmitted=`grep -oP "transmitted = \K[0-9]+" <<< ${result}`
  pubRate=`grep -oP "publish rate \(msg\/sec\) = \K[0-9]+" <<< ${result}`
  if [ -z "${SDKPERF_HOME}" ]
  then
    received=`grep -oP "received across all clients = \K[0-9]+" <<< ${result}`
    subRate=`grep -oP "receive rate \(msg\/sec aggregate\) = \K[0-9]+" <<< ${result}`
  else
    received=`grep -oP "received across all subscribers = \K[0-9]+" <<< ${result}`
    subRate=`grep -oP "subscriber rate \(msg\/sec across all subscribers\) = \K[0-9]+" <<< ${result}`
  fi

  subExpectedRate=$(expr ${expectedRate}*${fanout} | bc)
  subExpectedMsgs=$(expr ${expectedMsgs}*${fanout} | bc)
  local pubHighFloat=$(expr 1.1*${expectedRate} | bc)
  local subHighFloat=$(expr 1.1*${subExpectedRate} | bc)
  pubHigh=${pubHighFloat%.*}
  subHigh=${subHighFloat%.*}
  local pubLowFloat=$(expr 0.9*${expectedRate} | bc)
  local subLowFloat=$(expr 0.9*${subExpectedRate} | bc)
  pubLow=${pubLowFloat%.*}
  subLow=${subLowFloat%.*}

  if [[ ${pubRate} -gt ${pubLow} && ${pubRate} -lt ${pubHigh} ]]
  then
    echo "${GREEN}${BOLD}PASS: Publisher rate of ${pubRate} msg/sec within 10% of ${expectedRate}${RESET}"
  else 
    echo "${RED}${BOLD}FAIL: Publisher rate of ${pubRate} msg/sec not within 10% of ${expectedRate}${RESET}"
  fi

  if [ ${transmitted} -eq ${expectedMsgs} ]
  then
    echo "${GREEN}${BOLD}PASS: Publisher transmitted ${transmitted} messages${RESET}"
  else
    echo "${RED}${BOLD}FAIL: Publisher transmitted ${transmitted} messages, expected ${expectedMsgs}${RESET}"
  fi

  if [[ ${subRate} -gt ${subLow} && ${subRate} -lt ${subHigh} ]]
  then
    echo "${GREEN}${BOLD}PASS: Subscriber rate of ${subRate} msg/sec within 10% of ${subExpectedRate}${RESET}"
  else 
    echo "${RED}${BOLD}FAIL: Subscriber rate of ${subRate} msg/sec not within 10% of ${subExpectedRate}${RESET}"
  fi

  if [ ${received} -eq ${subExpectedMsgs} ]
  then
    echo "${GREEN}${BOLD}PASS: Subscriber received ${received} messages${RESET}"
  else
    echo "${RED}${BOLD}FAIL: Subscriber received ${received} messages, expected ${subExpectedMsgs}${RESET}"
  fi
}
