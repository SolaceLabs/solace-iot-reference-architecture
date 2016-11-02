---
layout: default
title: Solace Testing in AWS
---

## AIM
The aim of this project is to enable Solace internal staff to quickly enable and test IoT reference architecture in AWS.
The IoT reference architecture itself is evolving along with the features/functionality within it.  Therefore this is a phase one of a work in progress that will evolve with reference architecture itself.

## Applicability
This architecture is presently best suited for use cases where there is a large amount of messages towards the core connected services, but few messages downbound to devices.  Request/replay in both directions is supported.
Also MQTT svc1 downbound towards devices is not supported.

## Future architecture:
![]({{ site.baseurl }}/images/IoTArchFuture.png)

1.	Centralized Authentication service to offload client authentication, (likely OAUTH2 or OpenId Connect based)
2.	Client aware or per client authorization to publish subscribe resources
3.	Distributed core VMRs that are scalable and fault tolerant
4.	Efficient global addressing to enable devices to connect anywhere in the EDGE layer and be reachable by back end services.
5.	Fault tolerant and efficient load balancers
6.	Properly configured firewalls and TLS security

## Current architecture: *(Work yet to be done struck through)*
![]({{ site.baseurl }}/images/IoTArchPresent.png)

1.  ~~Centralized Authentication service to offload client authentication, (likely OAUTH2 or OpenId Connect based)~~
2.	~~Client aware or per client authorization to publish subscribe resources~~
3.	~~Distributed core VMRs that are scalable and fault tolerant~~
4.	~~Efficient~~ global addressing to enable devices to connect anywhere in the EDGE layer and be reachable by back end services.
5.	~~Fault tolerant~~ and efficient load balancers
6.	Properly configured firewalls ~~and TLS security~~

# Creation of this reference architecture is fully automated with minimal manual configuration.

## Prerequisites:
1.	AWS account with access to your valid:
    *	aws_access_key
    *	aws_access_secret
2.	Access to the AWS web console in your region, will be used for rest of the setup.

# Preparation steps:
1.  Create or identify the access key pair you wish to use.

![]({{ site.baseurl }}/images/GetPem.png)

Get the cloud-init.sh script from here:

    {{ site.repository }}/blob/master/Cloud-Init/init.sh

## You will need to save a copy with edit for these variables

```
export AWS_ACCESS_KEY_ID=XXX       # <Your AWS Access key>
export AWS_SECRET_ACCESS_KEY=XXX   #<Your AWS Key Secret>
export AWS_KEY_NAME=XXX            #<a TLS PEM you use to access AWS instances>
export AWS_KEY_VALUE=XXX           #<actual content of private key>
```

## Optionally you can edit these variables to modify VMRs and cluster

## VMR perticulars

```
export AWS_GROUP_ID=CREATE            #<CREATE will create new policy or provide your security Policy ID>
export AWS_INSTANCE_TYPE=t2.medium    #<t2.medium will be minimum requirement, its not free>
export AWS_INSTANCE_NAME="AnsibleVMR" #<What ever name you want to see in AWS console>
export AWS_INSTANCE_AMI=ami-3fa7d528  #Latest released 7.2 Eval
```

## Change to define netwoork

```
export VMR_CORE_CLUSTER=N # <[Y|N] Do you want a fully redundent core, DO NOT SET TO Y>
export VMR_EDGE_NODES=1   # <[0...MAX_BRIDGE] # of edge VMRs, 0 means core only>
export AWS_ELB=N          #   <[Y|N|ELB_NAME]Front VMRs with AWS Elastic_LOAD_BALANCER, there create new or use existing ELB_NAME>
```

# Proceed to create an AMI instance from which to launch 

## Specify Ubuntu as your test/bootstrap server, following steps are specific to Ubuntu

![]({{ site.baseurl }}/images/CreateInstance1.png)

## Use instance size that best fits your testing needs, smallest for quick tests, or match VMR instance size

![]({{ site.baseurl }}/images/CreateInstance2.png)

## The Advanced Details section is where you spacify your previously defined init.sh

![]({{ site.baseurl }}/images/CreateInstance3.png)

## You can specify a security group, name tag etc. for this instance or just use defaults. Then specify same PEM file as above

![]({{ site.baseurl }}/images/UsePem.png)

## Your test/bootstrap instance will now start and you see creation via AWS Console

To further see the progress access the test/bootstrap instance you created as usual:

```ssh –I <yourCert>.pem ubuntu@<yourExternalIP>```

To troubleshoot and monitor progress of startup:

    * /var/log/cloud-init-output.log
    * /var/log/ansible.log

# Test procedures

To see the IP/DNS of the core appliances and Elastic LoadBalancer, please see ~/test_env/Ansible/hosts and VMRs.yml

```
CORE=`cat ~/test_env/Ansible/VMRs.yml | shyaml get-value Instances.0.Instance.PRIVATE_DNS`
EDGE=`tail -n 1 ~/test_env/Ansible/hosts`
cd ~/test_env/Tests
```

## Test QoS0 traffic from multiple edge devices into core server

This traffic pattern shows multiple devices connected across load balanced edge VMRs publishing Q0S0 to core applications.

Edge MQTT devices publish to in/"deviceId"/svc0/DATADESCRIPTION

```
export TOPIC_PREFIX=in/
export TOPIC_POSTFIX=/svc0/DATADESCRIPTION
~/test_env/Tests/sol_QoS0_IoT_E2C.sh 20 ${CORE} ${EDGE} solaceDirectIoT10 2> /dev/null
```

## Test QoS1 traffic from multiple edge device into core server

This traffic pattern shows multiple devices connected across load balanced edge VMRs publishing svc1 to core applications.

Edge MQTT devices publish to in/"deviceId"/svc1/DATADESCRIPTION

```
export TOPIC_PREFIX=in/
export TOPIC_POSTFIX=/svc1/DATADESCRIPTION
~/test_env/Tests/sol_QoS1_IoT_E2C.sh 20 ${CORE} ${EDGE} solaceDirectIoT10 2> /dev/null
```

## Test direct traffic from core server out to edge devices

This traffic pattern shows core servers publishing out to multiple devices connected across load balanced edge VMRs.

Edge Core servers publish to out/"deviceId"/DATADESCRIPTION

```
export TOPIC_PREFIX=out/
export TOPIC_POSTFIX=/DATADESCRIPTION
~/test_env/Tests/sol_direct_IoT_C2E.sh 20 ${CORE} ${EDGE} solaceDirectIoT10 2> /dev/null
```

## Test Request message coming from load balanced edge devices into core appliations.

This traffic pattern shows multiple devices connected across load balanced edge VMRs sending requests to core applications.

Edge MQTT devices publish request to in/"deviceId"/svc0/request/desc

Core Java devices publish reply to out/"deviceId"/svc0/reply/desc


```
export TOPIC_PREFIX=in/
export TOPIC_POSTFIX=/svc0/request/desc
export REPLY_PREFIX=out/
export TOPIC_POSTFIX=/svc0/reply/desc
~/test_env/Tests/sol_ReqRep_IoT_E2C.sh 20 ${CORE} ${EDGE} solaceDirectIoT10 2> /dev/null
```
