#[TODO] Hack to let VMRs come update
echo "`date` Configure VMRs - Waiting for VMRs to come up"
unreachable=1
while [ ${unreachable} -ne 0 ] ; do 
   pingResult=`ansible -i ./hosts -m ping VMRs`
   unreachable=`echo ${pingResult} | grep -c UNREACHABLE`
   echo "Unreachable VMRs 1=TRUE 0=FALSE:  Value:${unreachable}" 
done

# Now the base OS is up lets wait until SolOS is responsive to SEMP
ansible-playbook -i ./hosts -c local VerifyAliveSEMP.yml -v

echo "`date` Configure VMRs - Configure Edge Queues"
ansible-playbook -i ./hosts -c local ConfigEdgeQueuesSEMP.yml -v

echo "`date` Configure VMRs - Configure Core Queue"
ansible-playbook -i ./hosts -c local ConfigCoreQueueSEMP.yml -v

echo "`date` Configure VMRs - Configure Edge Bridges"
ansible-playbook -i ./hosts -c local ConfigEdgeBridgesSEMP.yml -v

echo "`date` Configure VMRs - Configure Core Bridges"
ansible-playbook -i ./hosts -c local ConfigCoreBridgesSEMP.yml -v

if [ ${AWS_ELB} != "N" ]; then
   # Need to set up to use aws console
   ### WARNING SCRIPT ERROR IN THIS CODE BLOCK WILL LEAK SECURITY CREDENTIALS
   ansible-playbook -i ./hosts -c local EnableAWS.yml -v
   if [ ${AWS_ELB} == "Y" ]; then
      AWS_ELB="IOT-LB-`date | md5sum | head -c 5`"

      lb_out=`aws elb create-load-balancer --load-balancer-name ${AWS_ELB} --listeners "[
             {\"Protocol\": \"TCP\", \"LoadBalancerPort\": ${MQTT}, \"InstanceProtocol\": \"TCP\", \"InstancePort\": ${MQTT}},
             {\"Protocol\": \"TCP\", \"LoadBalancerPort\": ${MQTTS}, \"InstanceProtocol\": \"TCP\", \"InstancePort\": ${MQTTS}},
             {\"Protocol\": \"TCP\", \"LoadBalancerPort\": ${MQTTWS}, \"InstanceProtocol\": \"TCP\", \"InstancePort\": ${MQTTWS}},
             {\"Protocol\": \"TCP\", \"LoadBalancerPort\": ${MQTTWSS}, \"InstanceProtocol\": \"TCP\", \"InstancePort\": ${MQTTWSS}},
             {\"Protocol\": \"TCP\", \"LoadBalancerPort\": ${REST}, \"InstanceProtocol\": \"TCP\", \"InstancePort\": ${REST}},
             {\"Protocol\": \"TCP\", \"LoadBalancerPort\": ${RESTS}, \"InstanceProtocol\": \"TCP\", \"InstancePort\": ${RESTS}},
             {\"Protocol\": \"TCP\", \"LoadBalancerPort\": ${HTTP}, \"InstanceProtocol\": \"TCP\", \"InstancePort\": ${HTTP}},
             {\"Protocol\": \"TCP\", \"LoadBalancerPort\": ${HTTPS}, \"InstanceProtocol\": \"TCP\", \"InstancePort\": ${HTTPS}},
             {\"Protocol\": \"TCP\", \"LoadBalancerPort\": ${SEMP}, \"InstanceProtocol\": \"TCP\", \"InstancePort\": ${SEMP}},
             {\"Protocol\": \"TCP\", \"LoadBalancerPort\": ${SEMPS}, \"InstanceProtocol\": \"TCP\", \"InstancePort\": ${SEMPS}},
             {\"Protocol\": \"TCP\", \"LoadBalancerPort\": ${SMF}, \"InstanceProtocol\": \"TCP\", \"InstancePort\": ${SMF}},
             {\"Protocol\": \"TCP\", \"LoadBalancerPort\": ${SMFS}, \"InstanceProtocol\": \"TCP\", \"InstancePort\": ${SMFS}},
             {\"Protocol\": \"TCP\", \"LoadBalancerPort\": ${SMFC}, \"InstanceProtocol\": \"TCP\", \"InstancePort\": ${SMFC}}
             ]"\
          --subnets ${AWS_SUBNET_ID}\
          --security-groups ${AWS_GROUP_ID}`

   fi
   aws elb register-instances-with-load-balancer --load-balancer-name ${AWS_ELB} --instances `echo ${vmr_edge_ID} | tr -d "[,]"`
   aws elb configure-health-check --load-balancer-name ${AWS_ELB} --health-check "Target=TCP:${SMF},Interval=5,UnhealthyThreshold=3,HealthyThreshold=2,Timeout=2"
   ansible-playbook -i ./hosts -c local DisableAWS.yml -v
   ### END CODE BLOCK

   echo "" >> ./hosts # Now add the LB into the hosts file for documentation
   echo "[LOAD_BALANCER]" >> ./hosts
   echo `echo $lb_out | jq -r '.DNSName'` >> ./hosts
fi
