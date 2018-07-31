# Autoscale IoT solution with AWS Cloud Formation, Cloud Watch, and AutoScale Groups

This project exemplifies using AWS autoscale groups in conjunction with Solace PubSub+ software message broker standard edition to build dynamically scallable multiprotocol messaging clusters.

There is a 3 tier architecture.  Starting at the client edge:
 * A loadbalancer layer that abstracts the complexity of the autoscale group.  Clients have a single connection point.
 * Scalable edge message brokers layer that handle a dynamic client count and workload.
 * Consolidated core message broker layer that provides a simple connectivity point for back end applications. 

![alt text](/images/aws_autoscale.png "autoscale components")


You will need to provide the following as inputs, they are not created in these templates:
 * Solace PubSub+ AMIid, 
 * existing VPC, 
 * existing Subnets, and 
 * existing security groups

 There are several ways to obtain a Solace PubSub+ Standard AMI reference.  A simple method is to view it in the AWS Marketplace.
Once logged into AWS folow the following link, select correct region and note AMI:
https://aws.amazon.com/marketplace/server/configuration?productId=33e0d3e8-860c-4411-89bd-afce4dc59c64&ref_=psb_cfg_continue

![alt text](/images/obtain_ami.png "solace in marketplace")

Click below to launch in AWS Cloud Formation:   

<a href="https://console.aws.amazon.com/cloudformation/home#/stacks/new?stackName=AutoScale&templateURL=https://s3.amazonaws.com/kbarr/solace-aws-iot-autoscale/latest/templates/solace-iot.template" target="_blank">
    <img src="/images/launch-button-existing.png"/>
</a>


