#!/bin/bash

#[TODO] Need proper init.sh versioning

# Credentials and locality
# Replace XXX with your credentials, MANDITORY
export AWS_ACCESS_KEY_ID=XXX     #Your AWS Access key
export AWS_SECRET_ACCESS_KEY=XXX #Your AWS Key Secret
export AWS_KEY_NAME=XXX          #A TLS PEM you use to access AWS instances. Do not include the .pem extension in the name.
export AWS_KEY_VALUE=XXX         #Actual content of private key, everything between "BEGIN RSA PRIVATE KEY-----" and "-----END RSA PRIVATE KEY"

# VMR particulars
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
export AWS_VPC_ID=`wget -q -O - http://instance-data/latest/meta-data/network/interfaces/macs/${MAC}vpc-id`

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

echo "`date` Grab Ansible, git etc..."
sudo apt-get -y install bc
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
ansible localhost -m git -a "repo=https://github.com/SolaceLabs/Solace_testing_in_AWS dest=/home/ubuntu/test_env"
chmod 744 /home/ubuntu/test_env/Tests/*sh

# Setup Enviroemental variables
##################################
source /home/ubuntu/test_env/Cloud-Init/setEnvironment.bash

# Setup Security
#################
source /home/ubuntu/test_env/Cloud-Init/setSecurity.bash

# Create VMRs
#############
source /home/ubuntu/test_env/Cloud-Init/createVMRs.bash

# Create VMRs
#############
source /home/ubuntu/test_env/Cloud-Init/configVMRs.bash

# Settup test environment
##########################
source /home/ubuntu/test_env/Cloud-Init/setTestEnv.bash

# Cleanup and exit
###################
cd /home
chown -R ubuntu:ubuntu /home/ubuntu
