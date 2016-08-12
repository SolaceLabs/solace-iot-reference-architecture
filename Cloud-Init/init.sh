#!/bin/bash

# Credentials and locality
# Replace XXX with your credentials and local info 
export AWS_ACCESS_KEY_ID=XXX
export AWS_SECRET_ACCESS_KEY=XXX
export AWS_SUBNET_ID=XXX<From previous screen selection>
export AWS_GROUP_ID=XXX<Your security Policy>
export AWS_REGION=XXX<[us-east-1|us-west-1|ap-southeast-1|eu-central-1|eu-west-1|...>

# Host Setup
sudo apt-get update
sudo apt-get -y upgrade
sudo apt-get -y install git
sudo  apt-get -y install ansible
sudo apt-get -y install python-pip
sudo apt-get -y install unzip
sudo pip install boto
sudo pip install boto3


# Download tests
ansible localhost -m git -a "repo=https://github.com/KenBarr/mqtt3.1.1_1.1.0_test dest=test_env"

# Inject sdkperf_java into test environment, using ken.barr@solacesystems.com as marketing token
wget http://sftp.solacesystems.com/download/SDKPERF_JAVA?mkt_tok=eyJpIjoiWVRZeE1tUm1OamMxTkdRMCIsInQiOiJ6MGZWWGFXOVhzTWdIMmtEamk4R0wrSlNHeHZRbHV5aldKNDNXeTVmdUlRVUl2enNoTEdUaW9LUE1ob1FzUVVDYVUweTNnaFh6dWh3YW1ZM0hVb25BK0s2bXdjQWx4MnU1a1V6dE1EWWVHOD0ifQ%3D%3D

mv SDKPERF_JAVA\?mkt_tok\=eyJpIjoiWVRZeE1tUm1OamMxTkdRMCIsInQiOiJ6MGZWWGFXOVhzTWdIMmtEamk4R0wrSlNHeHZRbHV5aldKNDNXeTVmdUlRVUl2enNoTEdUaW9LUE1ob1FzUVVDYVUweTNnaFh6dWh3YW1ZM0hVb25BK0s2bXdjQWx4MnU1a1V6dE1EWWVHOD0ifQ%3D%3D  test_env\Sdkperf\sdkperf_java.zip

cd ~/test_env/Sdkperf
unzip sdkperf_java.zip
cd ~

# Create a VMR
ansible-playbook test_env/Ansible/CreateVMR.yml

# Set Test environmental variable 
echo "export SOLACE_HOST="`grep private_ip /var/log/cloud-init-output.log | tr -d "private_ip: ,\""` >> ~/.bashrc
