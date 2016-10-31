#SIZES='100 500 1024 2048 4096 10240 20480'
SIZES='100 500 1024 2048'

case "${TEST_TYPE}" in

#Solace IoT Tests
#=================
solaceDirectIoT10)
        SDKPERF_HOME=~/test_env/Sdkperf
        STREAM_COUNT=10
        SDKPERF_JAVA=sol-sdkperf/sdkperf_java.sh
        SDKPERF_MQTT=sdkperf-mqtt/sdkperf_mqtt.sh
        rate[100]=1000
        rate[500]=1000
        rate[1024]=1000
        rate[2048]=1000
        ;;

solaceDirectIoT100)
        SDKPERF_HOME=~/test_env/Sdkperf
        STREAM_COUNT=100
        SDKPERF_JAVA=sol-sdkperf/sdkperf_java.sh
        SDKPERF_MQTT=sdkperf-mqtt/sdkperf_mqtt.sh
        rate[100]=100
        rate[500]=100
        rate[1024]=100
        rate[2048]=100
        ;;

#Solace JCSMP Tests
#=================

solaceDirectJCSMP10)
	SDKPERF_HOME=~/test_env/sdkperf
	STREAM_COUNT=10
	SDKPERF=sdkperf_java.sh
	rate[100]=650000
	rate[500]=450000
	rate[1024]=450000
	rate[2048]=330000
	rate[4096]=160000
	rate[10240]=82000
	rate[20480]=52000
	;;

solaceDirectJCSMP100)
	SDKPERF_HOME=~/test_env/sdkperf
	STREAM_COUNT=100
	SDKPERF=sdkperf_java.sh
	rate[100]=550000
	rate[500]=330000
	rate[1024]=330000
	rate[2048]=230000
	rate[4096]=160000
	rate[10240]=75000
	rate[20480]=42000
	;;

solacePersistentJCSMP10)
	SDKPERF_HOME=~/test_env/sdkperf
	STREAM_COUNT=10
	SDKPERF=sdkperf_java.sh
	rate[100]=57000
	rate[500]=56000
	rate[1024]=55000
	rate[2048]=47000
	rate[4096]=30000
	rate[10240]=25000
	rate[20480]=22000
	;;

solacePersistentJCSMP100)
	SDKPERF_HOME=~/test_env/sdkperf
	STREAM_COUNT=100
	SDKPERF=sdkperf_java.sh
	rate[100]=47000
	rate[500]=45000
	rate[1024]=43000
	rate[2048]=40000
	rate[4096]=30000
	rate[10240]=20000
	rate[20480]=12000
	;;

#Solace JMS Tests
#=================

solaceDirectJMS10)
	SDKPERF_HOME=~/test_env/sdkperf
	STREAM_COUNT=10
	SDKPERF=sdkperf_jms.sh
	rate[100]=430000
	rate[500]=430000
	rate[1024]=400000
	rate[2048]=330000
	rate[4096]=300000
	rate[10240]=77000
	rate[20480]=50000
	;;

solaceDirectJMS100)
	SDKPERF_HOME=~/test_env/sdkperf
	STREAM_COUNT=100
	SDKPERF=sdkperf_jms.sh
	rate[100]=430000
	rate[500]=430000
	rate[1024]=400000
	rate[2048]=330000
	rate[4096]=300000
	rate[10240]=77000
	rate[20480]=50000
	;;

solacePersistentJMS10)
	SDKPERF_HOME=~/test_env/sdkperf
	STREAM_COUNT=10
	SDKPERF=sdkperf_jms.sh
	rate[100]=54000
	rate[500]=54000
	rate[1024]=52000
	rate[2048]=47000
	rate[4096]=20000
	rate[10240]=9000
	rate[20480]=5000
	;;

solacePersistentJMS100)
	SDKPERF_HOME=~/test_env/sdkperf
	STREAM_COUNT=100
	SDKPERF=sdkperf_jms.sh
	rate[100]=45000
	rate[500]=44000
	rate[1024]=42000
	rate[2048]=40000
	rate[4096]=20000
	rate[10240]=9000
	rate[20480]=4000
	;;

#Solace CSMP Tests
#=================

solaceDirectCSMP10)
	STREAM_COUNT=10
	SDKPERF=sdkperf_c_7.1.1
	rate[100]=1500000
	rate[500]=1200000
	rate[1024]=800000
	rate[2048]=490000
	rate[4096]=250000
	rate[10240]=90000
	rate[20480]=51000
	;;

solaceDirectCSMP100)
	STREAM_COUNT=100
	SDKPERF=sdkperf_c_7.1.1
	rate[100]=1500000
	rate[500]=1200000
	rate[1024]=800000
	rate[2048]=490000
	rate[4096]=250000
	rate[10240]=90000
	rate[20480]=51000
	;;

solacePersistentCSMP10)
	STREAM_COUNT=10
	SDKPERF=sdkperf_c_7.1.1
	rate[100]=55000
	rate[500]=55000
	rate[1024]=52000
	rate[2048]=48000
	rate[4096]=42000
	rate[10240]=32000
	rate[20480]=21000
	;;

solacePersistentCSMP100)
	STREAM_COUNT=100
	SDKPERF=sdkperf_c_7.1.1
	rate[100]=55000
	rate[500]=55000
	rate[1024]=52000
	rate[2048]=48000
	rate[4096]=42000
	rate[10240]=32000
	rate[20480]=21000
	;;

*)
	echo "${RED}${BOLD}FAIL: Invalid Test \"${testType}\"${RESET}"
	exit 
	;;
esac
