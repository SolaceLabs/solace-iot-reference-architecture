#!/bin/bash -xe
echo "`date` INFO: Enable CentOS-Base"
sed -i 's/enabled=0/enabled = 1/g' /etc/yum.repos.d/CentOS-Base.repo
sed -i 's/enabled = 0/enabled = 1/g' /etc/yum.repos.d/CentOS-Base.repo

echo "`date` INFO:Grab the aws-cfn-bootstrap rpm"
cd /root
mkdir -p aws-cfn-bootstrap
curl -o aws-cfn-bootstrap/aws-cfn-bootstrap-latest.amzn1.noarch.rpm https://s3.amazonaws.com/cloudformation-examples/aws-cfn-bootstrap-latest.amzn1.noarch.rpm
chown -R root.root ~/aws-cfn-bootstrap

echo "`date` INFO:Allow repo mgmt"
yum install -y epel-release
yum install -y createrepo

echo "`date` INFO:Create a aws-cfn-bootstrap repo"                         
createrepo /root/aws-cfn-bootstrap
chmod -R o-w+r /root/aws-cfn-bootstrap

echo "[local]
name=AWS CFN Bootstrap
baseurl=file:///root/aws-cfn-bootstrap
enabled=1
gpgcheck=0" > /etc/yum.repos.d/aws-cfn-bootstrap.repo

echo "`date` INFO:Install aws-cfn-bootstrap"
yum install -y yum aws-cfn-bootstrap
ln -sf /usr/local/lib/python2.7/site-packages/cfnbootstrap /usr/lib/python2.7/site-packages/cfnbootstrap

echo "`date` INFO:Install awscli"
yum -y install python-pip
pip install pystache
pip install argparse
pip install python-daemon
pip install requests
pip install awscli
