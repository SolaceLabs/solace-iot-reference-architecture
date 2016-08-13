#!/bin/bash

# Credentials and locality
# Replace XXX with your credentials and local info 
export AWS_ACCESS_KEY_ID=XXX <Your AWS Access key>
export AWS_SECRET_ACCESS_KEY=XXX <Your AWS Key Secret>
export AWS_SUBNET_ID=XXX <From previous screen selection>
export AWS_GROUP_ID=XXX <Your security Policy>
export AWS_REGION=XXX <[us-east-1|us-west-1|ap-southeast-1|eu-central-1|eu-west-1|...]>
export AWS_KEY_NAME=XXX <a TLS PEM you use to access AWS instances>
export AWS_INSTANCE_TYPE=t2.medium <t2.medium will be minimum requirement, its not free>
export AWS_INSTANCE_NAME="MyVMR" <What ever name you want to see in AWS console>

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
echo "localhost" > /etc/ansible/hosts
cd /home/ubuntu/test_env/Ansible
ansible-playbook -i "localhost," -c local CreateVMR.yml

cd /home
chown -R ubuntu /home/ubuntu


# Set Test environmental variable 
echo "export SOLACE_HOST="`grep private_ip /var/log/cloud-init-output.log | tr -d "private_ip: ,\""` >> /home/ubuntu/.bashrc
