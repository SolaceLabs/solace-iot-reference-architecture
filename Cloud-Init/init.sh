#!/bin/bash

# Credentials and locality
# Replace XXX with your credentials and local info 
export AWS_ACCESS_KEY_ID=XXX #<Your AWS Access key>
export AWS_SECRET_ACCESS_KEY=XXX #<Your AWS Key Secret>
export AWS_GROUP_ID=XXX #<Your security Policy>
export AWS_KEY_NAME=XXX #<a TLS PEM you use to access AWS instances>
export AWS_KEY_VALUE=XXX #<actual content of private key, everything between "BEGIN RSA PRIVATE KEY-----" and "-----END RSA PRIVATE KEY">

export SDKPERF_JAVA=XXX #<The link to download sdkperf_java if required>

export AWS_INSTANCE_TYPE=t2.medium #<t2.medium will be minimum requirement, its not free>
export AWS_INSTANCE_NAME="AnsibleVMR" #<What ever name you want to see in AWS console>
export AWS_INSTANCE_AMI=XXX #<AMI instance id for VMR>

# Will populate this section based on the AWS configuration
export AWS_AVAILABILITY_ZONE=`wget -q -O - http://instance-data.ec2.internal/latest/meta-data/placement/availability-zone`
export AWS_REGION=`echo ${AWS_AVAILABILITY_ZONE::-1}`
export MAC=`wget -q -O - http://instance-data/latest/meta-data/network/interfaces/macs/`
export AWS_SUBNET_ID=`wget -q -O - http://instance-data/latest/meta-data/network/interfaces/macs/${MAC}subnet-id`

# Change to define 
export VMR_CORE_CLUSTER=N # <[Y|N] Do you want a fully redundent core, N will give single core, Y will give Active/Standby/Quorum>
export VMR_EDGE_NODES=1 # <[0...MAX_BRIDGE_CONNECTIONS] Number of client connected edge nodes, 0 means connect to core>
export VMR_ELASTIC_IP=N #  <Front VMRs with AWS Elastic_IP>

if [ ${VMR_CORE_CLUSTER} == "Y" ]; then
   core_count=3
else
   core_count=1
fi

export AWS_INSTANCE_COUNT=$((core_count+${VMR_EDGE_NODES}))
export ANSIBLE_HOST_KEY_CHECKING=False

# Host Setup
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

echo "`date` Install AWS tools"
sudo pip install boto
sudo pip install awscli

echo "`date` Install XML parsing for Ansible"
sudo apt-get -y install python-dev libxml2-dev libxslt1-dev zlib1g-dev
sudo pip install lxml
sudo ansible-galaxy install cmprescott.xml

echo "`date` Place private key on test hosts"
echo "-----BEGIN RSA PRIVATE KEY-----" > /home/ubuntu/${AWS_KEY_NAME}.pem
echo ${AWS_KEY_VALUE} | tr " " "\n" >> /home/ubuntu/${AWS_KEY_NAME}.pem
echo "-----END RSA PRIVATE KEY-----" >> /home/ubuntu/${AWS_KEY_NAME}.pem
chmod 600  /home/ubuntu/${AWS_KEY_NAME}.pem

echo "`date` Download tests"
ansible localhost -m git -a "repo=https://github.com/KenBarr/Solace_testing_in_AWS dest=/home/ubuntu/test_env"
chmod 744 /home/ubuntu/test_env/Tests/*sh

echo "`date` Create a VMRs"
cd /home/ubuntu/test_env/Ansible
mkdir ./group_vars
mkdir ./library
cp /etc/ansible/roles/cmprescott.xml/library/xml ./library
LOCALHOST_VAR_FILE="./group_vars/LOCALHOST/localhost.yml"
mkdir ./group_vars/LOCALHOST
VMRs_VAR_FILE="./group_vars/VMRs/VMRs.yml"
mkdir ./group_vars/VMRs
echo "[LOCALHOST]" > ./hosts
echo "localhost" >> ./hosts
ansible-playbook -i ./hosts -c local CreateVMR.yml -v

echo "`date` Configure VMRs - Create host and variable files"
ansiblePasswd=`date | md5sum | head -c 32`
echo "---" > ${LOCALHOST_VAR_FILE}
vmr_core="VMRs_CORE: ["
vmr_edge="VMRs_EDGE: ["
echo "" >> ./hosts
echo "[VMRs]" >> ./hosts
echo "---" > ${VMRs_VAR_FILE}
echo "ANSIBLE_USERNAME: ansibleAdmin" >> ${LOCALHOST_VAR_FILE}
echo "ANSIBLE_PASSWORD: ${ansiblePasswd}" >>${LOCALHOST_VAR_FILE}
echo "ANSIBLE_SEMP_PORT: 8080" >> ${LOCALHOST_VAR_FILE}
echo "ANSIBLE_USERNAME: ansibleAdmin" >> ${VMRs_VAR_FILE}
echo "ANSIBLE_PASSWORD: ${ansiblePasswd}" >> ${VMRs_VAR_FILE}
echo "[VMRs:children]" >> ./hosts
echo "VMRs_CORE" >> ./hosts
echo "VMRs_EDGE" >> ./hosts
echo "" >> ./hosts
echo "[VMRs_CORE]" >> ./hosts

count=0
core="true"
for file in $( ls VMR* ); do
   vmr_ip=`grep PRIVATE_IP $file | tr -d PRIVATE_IP=`
   vmr_name=`grep PRIVATE_DNS $file`
   vmr_name=${vmr_name#PRIVATE_DNS=}
   vmr_name=${vmr_name%.ec2.internal}  
   if [ ${count} == ${core_count} ]; then
      echo "" >> ./hosts
      echo "[VMRs_EDGE]" >> ./hosts
      core="false"
   fi
   echo "${vmr_ip} ansible_port=2222 ansible_user=sysadmin ansible_ssh_private_key_file=/home/ubuntu/${AWS_KEY_NAME}.pem" >> ./hosts
   if [ ${core} == "true" ]; then
      vmr_core="${vmr_core} ${vmr_ip}," 
   else
      vmr_edge="${vmr_edge} ${vmr_name},"
   fi
   count=$((count+1))
done
vmr_core="${vmr_core%,}]" # Replace the last "," with "]"
vmr_edge="${vmr_edge%,}]" # Replace the last "," with "]"
echo ${vmr_core} >> ${LOCALHOST_VAR_FILE}
echo ${vmr_edge} >> ${LOCALHOST_VAR_FILE}

#[TODO] Hack to let VMRs come update
echo "`date` Configure VMRs - Waiting for VMRs to come up"
unreachable=1
while [ ${unreachable} -ne 0 ] ; do 
   pingResult=`ansible -i ./hosts -m ping VMRs`
   unreachable=`echo ${pingResult} | grep -c UNREACHABLE`
   echo ${unreachable} 
done

sleep 180

echo "`date` Configure VMRs - Enable SEMP"
ansible-playbook -i ./hosts EnableSEMP.yml -v

echo "`date` Configure VMRs - Configure Edge Bridges"
ansible-playbook -i ./hosts -c local ConfigEdgeBridgesSEMP.yml -v

echo "`date` Configure VMRs - Configure Core Bridges"
ansible-playbook -i ./hosts -c local ConfigCoreBridgesSEMP.yml -v

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

cd /home
chown -R ubuntu:ubuntu /home/ubuntu