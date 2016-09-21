---
layout: default
title: Solace Testing in AWS
---

## AIM
The aim of this project is to enable Solace internal staff to quickly enable and test IoT reference architecture in AWS.
The IoT reference architecture itself is evolving along with the features/functionality within it.  Therefore this is a phase one of a work in progress that will evolve with reference architecture itself.

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

Creation of this reference architecture is fully automated with minimal manual configuration.

## Prerequisites:
1.	AWS account with access to your valid:
    *	aws_access_key
    *	aws_access_secret
2.	Access to the AWS web console in your region, will be used for rest of the setup.

## Preparation steps:
1.  Create or identify the access key pair you wish to use.

![]({{ site.baseurl }}/images/GetPem.png)

Get the cloud-init.sh script from here:

    {{ site.repository }}/blob/master/Cloud-Init/init.sh

# You will need to save a copy with edit for these variables

```
export AWS_ACCESS_KEY_ID=XXX       # <Your AWS Access key>
export AWS_SECRET_ACCESS_KEY=XXX   #<Your AWS Key Secret>
export AWS_KEY_NAME=XXX            #<a TLS PEM you use to access AWS instances>
export AWS_KEY_VALUE=XXX           #<actual content of private key>
```

# Optionally you can edit these variables to modify VMRs and cluster

```
# VMR perticulars
export AWS_GROUP_ID=CREATE            #<CREATE will create new policy or provide your security Policy ID>
export AWS_INSTANCE_TYPE=t2.medium    #<t2.medium will be minimum requirement, its not free>
export AWS_INSTANCE_NAME="AnsibleVMR" #<What ever name you want to see in AWS console>
export AWS_INSTANCE_AMI=ami-3fa7d528  #Latest released 7.2 Eval

# Change to define netwoork
export VMR_CORE_CLUSTER=N # <[Y|N] Do you want a fully redundent core, DO NOT SET TO Y>
export VMR_EDGE_NODES=1   # <[0...MAX_BRIDGE] # of edge VMRs, 0 means core only>
export AWS_ELB=N          #   <[Y|N|ELB_NAME]Front VMRs with AWS Elastic_LOAD_BALANCER, there create new or use existing ELB_NAME>
```

## Proceed to create an AMI instance from which to launch 

# Specify Ubuntu as your test/bootstrap server, following steps are specific to Ubuntu

![]({{ site.baseurl }}/images/CreateInstance1.png)

# Use instance size that best fits your testing needs, smallest for quick tests, or match VMR instance size

![]({{ site.baseurl }}/images/CreateInstance2.png)

# The Advanced Details section is where you spacify your previously defined init.sh

![]({{ site.baseurl }}/images/CreateInstance3.png)

# You can specify a security group, name tag etc. for this instance or just use defaults. Then specify same PEM file as above

![]({{ site.baseurl }}/images/UsePem.png)

# Your test/bootstrap instance will now start and you see creation via AWS Console

To further see the progress access the test/bootstrap instance you created as usual:

```ssh –I <yourCert>.pem ubuntu@<yourExternalIP>```

To troubleshoot and monitor progress of startup:

    * /var/log/cloud-init-output.log
    * /var/log/ansible.log
