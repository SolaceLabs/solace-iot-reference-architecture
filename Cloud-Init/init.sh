#!/bin/bash

#[TODO] Need proper init.sh versioning

# Credentials and locality
# Replace XXX with your credentials, MANDITORY
export AWS_ACCESS_KEY_ID=XXX     #Your AWS Access key
export AWS_SECRET_ACCESS_KEY=XXX #Your AWS Key Secret
export AWS_KEY_NAME=XXX          #a TLS PEM you use to access AWS instances
export AWS_KEY_VALUE=XXX         #actual content of private key, everything between "BEGIN RSA PRIVATE KEY-----" and "-----END RSA PRIVATE KEY"

# Add link to sdkperf if you want one installed
export SDKPERF_JAVA=??? #The link to download sdkperf_java if required, leave as ??? means no sdkperf

# VMR perticulars
export AWS_GROUP_ID=CREATE            #CREATE will create new policy or provide your security Policy ID
export AWS_INSTANCE_TYPE=t2.medium    #t2.medium will be minimum requirement, its not free
export AWS_INSTANCE_NAME="AnsibleVMR" #What ever name you want to see in AWS console
export AWS_INSTANCE_AMI=ami-3fa7d528  #Latest released 7.2 Eval

# Change to define network
#export VMR_CORE_CLUSTER=N #[Y|N] Do you want a fully redundent core, N will give single core, Y will give Active/Standby/Quorum
export VMR_CORE_CLUSTER=N  #[Y|N] Do you want a fully redundent core, DO NOT SET TO Y
export VMR_EDGE_NODES=1    #[0...MAX_BRIDGE_CONNECTIONS] Number of client connected edge nodes, 0 means connect to core
export AWS_ELB=N           # [Y|N|ELB_NAME]Front VMRs with AWS Elastic_LOAD_BALANCER, there create new or use existing ELB_NAME

# Change to define VMR persistent disk 
export VMR_DISK_NAME='/dev/sda1' #This is the single disk used by VMR, later we may want to change this for multiple disks
export VMR_DISK_TYPE='io1' #[io1|gp2]  Either iops specified or general perpose, gp2 is cheaper if no persistent msgs
export VMR_DISK_SIZE=30    #Size of disk, note we are using one disk for VMR and data, default is 30GBytes
export VMR_DISK_IOPS=1500  #max is 50 x VMR_DISK_SIZE, ignored for gp2 disks
export VMR_DISK_DoT='true' #Delete on Termination, if you delete the VMR do you want the disk to go away


#########################################
# Should not need to edit below this line
#########################################

# Will populate this section based on the AWS configuration
export AWS_AVAILABILITY_ZONE=`wget -q -O - http://instance-data.ec2.internal/latest/meta-data/placement/availability-zone`
export AWS_REGION=`echo ${AWS_AVAILABILITY_ZONE::-1}`
export MAC=`wget -q -O - http://instance-data/latest/meta-data/network/interfaces/macs/`
export AWS_SUBNET_ID=`wget -q -O - http://instance-data/latest/meta-data/network/interfaces/macs/${MAC}subnet-id`

# Constants
export ANSIBLE_ADMIN_NAME=admin
export ANSIBLE_ADMIN_PORT=8080
export VMR_ADMIN_NAME=sysadmin
export VMR_ADMIN_PORT=2222
export HTTP=80
export HTTPS=443
export SEMP=8080
export SEMPS=943
export SSH_DOCKER=22
export SSH_BASE=2222
export MQTT=1883
export MQTTS=8883
export MQTTWS=8000
export MQTTWSS=8443
export REST=9000
export RESTS=9443
export SMF=55555
export SMFC=55003
export SMFS=55443


if [ ${VMR_CORE_CLUSTER} == "Y" ]; then
   core_count=3
else
   core_count=1
fi

export AWS_INSTANCE_COUNT=$((core_count+${VMR_EDGE_NODES}))
export ANSIBLE_HOST_KEY_CHECKING=False

# Install software
###################
echo "`date` Need to use upgraded Ansible 2.1.x for some of the parsing features"
sudo apt-get -y install software-properties-common
sudo apt-add-repository -y ppa:ansible/ansible

echo "`date` Upgrade Ubuntu 14.04 to latests libraries"
sudo apt-get update
sudo apt-get -y upgrade

echo "`date` Grab Ansible, git ..."
sudo apt-get -y install git
sudo apt-get -y install ansible
sudo apt-get -y install python-pip
sudo apt-get -y install jq          # Command line json parser
sudo pip install shyaml             # Command line yaml parse
sudo pip install pexpect --upgrade  # Needed for ansible expect tasks

echo "`date` Install AWS tools"
sudo pip install boto               # Ansible AWS interface
sudo pip install awscli             # AWS CLI

echo "`date` Install XML parsing for Ansible"
sudo apt-get -y install python-dev libxml2-dev libxslt1-dev zlib1g-dev
sudo pip install lxml               # Ansible xml parsing, SEMP responses
sudo ansible-galaxy install cmprescott.xml

echo "`date` Download tests"
ansible localhost -m git -a "repo=https://github.com/KenBarr/Solace_testing_in_AWS dest=/home/ubuntu/test_env"
chmod 744 /home/ubuntu/test_env/Tests/*sh


# Setup Security
#################

echo "`date` Place private key on test hosts"
echo "-----BEGIN RSA PRIVATE KEY-----" > /home/ubuntu/${AWS_KEY_NAME}.pem
echo ${AWS_KEY_VALUE} | tr " " "\n" >> /home/ubuntu/${AWS_KEY_NAME}.pem
echo "-----END RSA PRIVATE KEY-----" >> /home/ubuntu/${AWS_KEY_NAME}.pem
chmod 600  /home/ubuntu/${AWS_KEY_NAME}.pem

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

echo "`date` Configure VMRs - Create host and variable files"
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
      lb_out=`aws elb create-load-balancer --load-balancer-name ${AWS_ELB}\
                                   --listeners "Protocol=TCP,LoadBalancerPort=${MQTT},InstanceProtocol=TCP,InstancePort=${MQTT}"\
                                   --listeners "Protocol=TCP,LoadBalancerPort=${MQTTS},InstanceProtocol=TCP,InstancePort==${MQTTS}"\
                                   --listeners "Protocol=TCP,LoadBalancerPort=${MQTTWS},InstanceProtocol=TCP,InstancePort=${MQTTWS}"\
                                   --listeners "Protocol=TCP,LoadBalancerPort=${MQTTWSS},InstanceProtocol=TCP,InstancePort${MQTTWSS}"\
                                   --listeners "Protocol=TCP,LoadBalancerPort=${REST},InstanceProtocol=TCP,InstancePort=${REST}"\
                                   --listeners "Protocol=TCP,LoadBalancerPort=${RESTS},InstanceProtocol=TCP,InstancePort=${RESTS}"\
                                   --listeners "Protocol=TCP,LoadBalancerPort=${SMF},InstanceProtocol=TCP,InstancePort=${SMF}"\
                                   --listeners "Protocol=TCP,LoadBalancerPort=${SMFS},InstanceProtocol=TCP,InstancePort=${SMFS}"\
                                   --listeners "Protocol=TCP,LoadBalancerPort=${SMFC},InstanceProtocol=TCP,InstancePort=${SMFC}"\
                                   --subnets ${AWS_SUBNET_ID}\
                                   --security-groups ${AWS_GROUP_ID}`
   fi
   aws elb register-instances-with-load-balancer --load-balancer-name ${AWS_ELB} --instances `echo ${vmr_edge_ID} | tr -d "[,]"`
   ansible-playbook -i ./hosts -c local DisableAWS.yml -v
   ### END CODE BLOCK

   echo "" >> ./hosts # Now add the LB into the hosts file for documentation
   echo "[LOAD_BALANCER]" >> ./hosts
   echo `echo $lb_out | jq -r '.DNSName'` >> ./hosts
fi

# Add aditional tooling
#######################
# Inject sdkperf_java into test environment, using ken.barr@solacesystems.com as marketing token
sudo apt-get -y install openjdk-7-jre-headless
sudo apt-get -y install unzip
mkdir /home/ubuntu/test_env/Sdkperf
cd /home/ubuntu/test_env/Sdkperf
wget http://sftp.solacesystems.com/download/${SDKPERF_JAVA}
mv ${SDKPERF_JAVA}  ./sdkperf_java.zip
unzip sdkperf_java.zip
chmod 744 /home/ubuntu/test_env/Sdkperf/*/*sh

# Get a copy of iperf that will run on VMR
sudo apt-get -y install iperf
cd /home/ubuntu
wget https://iperf.fr/download/fedora/iperf-2.0.5-13.fc21.x86_64.rpm

# Cleanup and exit
###################
cd /home
chown -R ubuntu:ubuntu /home/ubuntu