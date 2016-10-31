
echo "`date` Set up Security policy group of one is not provided"
cd /home/ubuntu/test_env/Ansible
echo "[LOCALHOST]" > ./hosts
echo "localhost" >> ./hosts
if [ ${AWS_GROUP_ID} == "CREATE" ]; then
   # Need to set up to use aws console
   ### WARNING SCRIPT ERROR IN THIS CODE BLOCK WILL LEAK SECURITY CREDENTIALS ###
   ansible-playbook -i ./hosts -c local EnableAWS.yml -v
   AWS_SG_NAME="IOT-SG-`date | md5sum | head -c 5`"
   sg_json=`aws ec2 create-security-group --group-name ${AWS_SG_NAME} --description "VMR Security group for IOT message traffic"`
   AWS_GROUP_ID=`echo $sg_json | jq -r '.GroupId'`
   #HTTP
   aws ec2 authorize-security-group-ingress --group-id  ${AWS_GROUP_ID} --protocol tcp --port ${HTTP} --cidr 0.0.0.0/0
   aws ec2 authorize-security-group-ingress --group-id  ${AWS_GROUP_ID} --protocol tcp --port ${HTTPS} --cidr 0.0.0.0/0
   #SEMP   
   aws ec2 authorize-security-group-ingress --group-id  ${AWS_GROUP_ID} --protocol tcp --port ${SEMP} --cidr 0.0.0.0/0
   aws ec2 authorize-security-group-ingress --group-id  ${AWS_GROUP_ID} --protocol tcp --port ${SEMPS} --cidr 0.0.0.0/0
   #SSH
   aws ec2 authorize-security-group-ingress --group-id  ${AWS_GROUP_ID} --protocol tcp --port ${SSH_DOCKER} --cidr 0.0.0.0/0
   aws ec2 authorize-security-group-ingress --group-id  ${AWS_GROUP_ID} --protocol tcp --port ${SSH_BASE} --cidr 0.0.0.0/0
   #MQTT
   aws ec2 authorize-security-group-ingress --group-id  ${AWS_GROUP_ID} --protocol tcp --port ${MQTT} --cidr 0.0.0.0/0
   aws ec2 authorize-security-group-ingress --group-id  ${AWS_GROUP_ID} --protocol tcp --port ${MQTTS} --cidr 0.0.0.0/0
   #MQTT/WS
   aws ec2 authorize-security-group-ingress --group-id  ${AWS_GROUP_ID} --protocol tcp --port ${MQTTWS} --cidr 0.0.0.0/0
   aws ec2 authorize-security-group-ingress --group-id  ${AWS_GROUP_ID} --protocol tcp --port ${MQTTWSS} --cidr 0.0.0.0/0   
   #REST
   aws ec2 authorize-security-group-ingress --group-id  ${AWS_GROUP_ID} --protocol tcp --port ${REST} --cidr 0.0.0.0/0
   aws ec2 authorize-security-group-ingress --group-id  ${AWS_GROUP_ID} --protocol tcp --port ${RESTS} --cidr 0.0.0.0/0    
   #SMF
   aws ec2 authorize-security-group-ingress --group-id  ${AWS_GROUP_ID} --protocol tcp --port ${SMF} --cidr 0.0.0.0/0
   aws ec2 authorize-security-group-ingress --group-id  ${AWS_GROUP_ID} --protocol tcp --port ${SMFC} --cidr 0.0.0.0/0
   aws ec2 authorize-security-group-ingress --group-id  ${AWS_GROUP_ID} --protocol tcp --port ${SMFS} --cidr 0.0.0.0/0
   ansible-playbook -i ./hosts -c local DisableAWS.yml -v
   ### END CODE BLOCK ###
fi

# Create and Configure VMRs
############################
echo "`date` Create a VMRs"
cd /home/ubuntu/test_env/Ansible
ansiblePasswd=`date | md5sum | head -c 32`
sed -i '/passwd/s/=PASSWORD/='${ansiblePasswd}'/' ./vmr_cloudInit.sh
mkdir ./group_vars
mkdir ./library
mkdir ./instances
echo "---" > ./instances/A_VMR_HEADER.yml
echo "Instances:" >> ./instances/A_VMR_HEADER.yml
cp /etc/ansible/roles/cmprescott.xml/library/xml ./library
LOCALHOST_VAR_FILE="./group_vars/LOCALHOST/localhost.yml"
mkdir ./group_vars/LOCALHOST
VMRs_VAR_FILE="./group_vars/VMRs/VMRs.yml"
mkdir ./group_vars/VMRs
echo "[LOCALHOST]" > ./hosts
echo "localhost" >> ./hosts
ansible-playbook -i ./hosts -c local CreateVMR_AWS.yml -v

#Re-asemble config fragments from created instances
ansible localhost -m assemble -a "src=./instances dest=./VMRs.yml"

echo "---" > ${LOCALHOST_VAR_FILE}
vmr_core_name="["
vmr_core_IP="["
vmr_core_ID="["
vmr_edge_name="["
vmr_edge_IP="["
vmr_edge_ID="["
echo ""       >> ./hosts
echo "[VMRs]" >> ./hosts
echo "---" > ${VMRs_VAR_FILE}
echo "ANSIBLE_USERNAME: ${ANSIBLE_ADMIN_NAME}"  >> ${LOCALHOST_VAR_FILE}
echo "ANSIBLE_PASSWORD: ${ansiblePasswd}"       >> ${LOCALHOST_VAR_FILE}
echo "ANSIBLE_SEMP_PORT: ${ANSIBLE_ADMIN_PORT}" >> ${LOCALHOST_VAR_FILE}
echo "ANSIBLE_USERNAME: ${ANSIBLE_ADMIN_NAME}"  >> ${VMRs_VAR_FILE}
echo "ANSIBLE_PASSWORD: ${ansiblePasswd}"       >> ${VMRs_VAR_FILE}
echo "[VMRs:children]" >> ./hosts
echo "VMRs_CORE"       >> ./hosts
echo "VMRs_EDGE"       >> ./hosts
echo ""                >> ./hosts
echo "[VMRs_CORE]"     >> ./hosts

count=0
core="true"
instanceCount=`grep -c Instance: VMRs.yml`
for (( index=0; index<$instanceCount; index++ )); do
   vmr_name=`cat ./VMRs.yml | shyaml get-value Instances.${index}.Instance.PRIVATE_DNS`
   vmr_ip=`cat ./VMRs.yml   | shyaml get-value Instances.${index}.Instance.PRIVATE_IP`
   vmr_id=`cat ./VMRs.yml   | shyaml get-value Instances.${index}.Instance.ID`
   vmr_name=${vmr_name%.ec2.internal}  
   if [ ${count} == ${core_count} ]; then
      echo "" >> ./hosts
      echo "[VMRs_EDGE]" >> ./hosts
      core="false"
   fi
   echo "${vmr_ip} ansible_port=${VMR_ADMIN_PORT} ansible_user=${VMR_ADMIN_NAME} ansible_ssh_private_key_file=/home/ubuntu/${AWS_KEY_NAME}.pem" >> ./hosts
   if [ ${core} == "true" ]; then
      vmr_core_name="${vmr_core_name} ${vmr_name}," 
      vmr_core_IP="${vmr_core_IP} ${vmr_ip}," 
      vmr_core_ID="${vmr_core_ID} ${vmr_id}," 
   else
      vmr_edge_name="${vmr_edge_name} ${vmr_name}," 
      vmr_edge_IP="${vmr_edge_IP} ${vmr_ip}," 
      vmr_edge_ID="${vmr_edge_ID} ${vmr_id}," 
   fi
   count=$((count+1))
done

echo "VMRs_CORE:" >> ${LOCALHOST_VAR_FILE}
echo "   NAMEs: ${vmr_core_name%,}]" >> ${LOCALHOST_VAR_FILE}
echo "   IPs: ${vmr_core_IP%,}]"     >> ${LOCALHOST_VAR_FILE}
echo "   IDs: ${vmr_core_ID%,}]"     >> ${LOCALHOST_VAR_FILE}
echo "VMRs_EDGE:" >> ${LOCALHOST_VAR_FILE}
echo "   NAMEs: ${vmr_edge_name%,}]" >> ${LOCALHOST_VAR_FILE}
echo "   IPs: ${vmr_edge_IP%,}]"     >> ${LOCALHOST_VAR_FILE}
echo "   IDs: ${vmr_edge_ID%,}]"     >> ${LOCALHOST_VAR_FILE}

