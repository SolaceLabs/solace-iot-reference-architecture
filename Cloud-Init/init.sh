#!/bin/bash

# Credentials and locality
# Replace XXX with your credentials and local info 
export AWS_ACCESS_KEY_ID=XXX #<Your AWS Access key>
export AWS_SECRET_ACCESS_KEY=XXX #<Your AWS Key Secret>
export AWS_GROUP_ID=XXX #<Your security Policy>
export AWS_KEY_NAME=XXX #<a TLS PEM you use to access AWS instances>
export AWS_KEY_VALUE=XXX #<actual content of private key>
export AWS_INSTANCE_TYPE=t2.medium #<t2.medium will be minimum requirement, its not free>
export AWS_INSTANCE_NAME="AnsibleVMR" #<What ever name you want to see in AWS console>
export AWS_INSTANCE_AMI=XXX #AMI instance id for VMR

export AWS_AVAILABILITY_ZONE=`wget -q -O - http://instance-data.ec2.internal/latest/meta-data/placement/availability-zone`
export AWS_REGION=`echo ${AWS_AVAILABILITY_ZONE::-1}`
export MAC=`wget -q -O - http://instance-data/latest/meta-data/network/interfaces/macs/`
export AWS_SUBNET_ID=`wget -q -O - http://instance-data/latest/meta-data/network/interfaces/macs/${MAC}subnet-id`

# Host Setup
sudo apt-get update
sudo apt-get -y upgrade
sudo apt-get -y install git
sudo apt-get -y install ansible
sudo apt-get -y install python-pip
sudo apt-get -y install openjdk-7-jre-headless
sudo apt-get -y install unzip
sudo apt-get -y install iperf
sudo pip install boto

# Place private key on test hosts
echo "-----BEGIN RSA PRIVATE KEY-----" > ${AWS_KEY_NAME}.pem
echo ${AWS_KEY_VALUE} | tr " " "\n" >> ${AWS_KEY_NAME}.pem
echo "-----END RSA PRIVATE KEY-----" >> ${AWS_KEY_NAME}.pem
chmod 600  /home/ubuntu/${AWS_KEY_NAME}.pem

# Get a copy of iperf that will run on VMR
cd /home/ubuntu
wget https://iperf.fr/download/fedora/iperf-2.0.5-13.fc21.x86_64.rpm

# Download tests
ansible localhost -m git -a "repo=https://github.com/KenBarr/Solace_testing_in_AWS dest=/home/ubuntu/test_env"
chmod 744 /home/ubuntu/test_env/Tests/*sh

# Inject sdkperf_java into test environment, using ken.barr@solacesystems.com as marketing token
mkdir /home/ubuntu/test_env/Sdkperf
cd /home/ubuntu/test_env/Sdkperf
wget http://sftp.solacesystems.com/download/SDKPERF_JAVA?mkt_tok=eyJpIjoiWVRZeE1tUm1OamMxTkdRMCIsInQiOiJ6MGZWWGFXOVhzTWdIMmtEamk4R0wrSlNHeHZRbHV5aldKNDNXeTVmdUlRVUl2enNoTEdUaW9LUE1ob1FzUVVDYVUweTNnaFh6dWh3YW1ZM0hVb25BK0s2bXdjQWx4MnU1a1V6dE1EWWVHOD0ifQ%3D%3D
mv SDKPERF_JAVA\?mkt_tok\=eyJpIjoiWVRZeE1tUm1OamMxTkdRMCIsInQiOiJ6MGZWWGFXOVhzTWdIMmtEamk4R0wrSlNHeHZRbHV5aldKNDNXeTVmdUlRVUl2enNoTEdUaW9LUE1ob1FzUVVDYVUweTNnaFh6dWh3YW1ZM0hVb25BK0s2bXdjQWx4MnU1a1V6dE1EWWVHOD0ifQ%3D%3D  ./sdkperf_java.zip
unzip sdkperf_java.zip
chmod 744 /home/ubuntu/test_env/Sdkperf/*/*sh

# Create a VMR
cd /home/ubuntu/test_env/Ansible
echo "localhost" > ./hosts
ansible-playbook -i ./hosts -c local CreateVMR.yml

# Configure VMR
export `cat /home/ubuntu/SOLACE_HOST`
echo "" >> ./hosts
echo "[VMRs]" >> ./hosts
echo "${SOLACE_HOST} ansible_port=2222 ansible_user=sysadmin ansible_ssh_private_key_file=${AWS_KEY_NAME}.pem" >> ./hosts

ansiblePasswd=`date | md5sum | head -c 32`
echo "" >> ./hosts
echo "[VMR_SEMPs]" >> ./hosts
echo "${SOLACE_HOST}" >> ./hosts

echo "" >> ./hosts
echo "[VMR_SEMPs:vars]" >> ./hosts
echo "ANSIBLE_USERNAME=asibleAdmin" >> ./hosts
echo "ANSIBLE_PASSWORD=${ansiblePasswd}" >> ./hosts
echo "ANSIBLE_PORT=8080" >> ./hosts

chown -R ubuntu:ubuntu /home/ubuntu