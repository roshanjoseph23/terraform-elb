# HA Infrastructure using Terraform

High Availability wordpress website infrastructure using Terraform.

# Features

 - Application LB
 - AutoScaling Group
 - VPC
 - EC2
 - S3
 - RDS
 - EFS
 - CloudFront
 - IAM Role
 - Bastion server

## Prerequisites

 - An IAM user with programmatic access with AWS Admin permission needs to be created.
 - Key pair needs to be created for SSH to Bastion server
 - An S3 needs to be created to backup tfstate

## AWS Access

    cat ~/.aws/credentials 
    [project]
    aws_access_key_id = "<access_key>"
    aws_secret_access_key = "<secret_access_key>"

## Provider

    provider "aws" {
    region                  = "us-east-1"
    profile                 = "project"
    shared_credentials_file = "~/.aws/credentials"
    }

## Variables

Variables are stored in file `terraform.tfvars`

    pub_az1  = "us-east-1a"
    pub_az2  = "us-east-1b"
    pub_az3  = "us-east-1c"
    priv_az1 = "us-east-1d"
    priv_az2 = "us-east-1e"
    priv_az3 = "us-east-1f"
    min      = 1
    max      = 1
    des      = 1
    ami      = "ami-0dba2cb6798deb6d8"
    s3origin = "myS3Origin"

Variables are called in command line using `-var-file="terraform.tfvars"`


## Application LB

 1. Wordpress admin panel is redirected to a master target group
 2. Website is loaded from slave target group

##  AutoScaling Group

 1. A master autoscaling group
 2. A slave autoscaling group

## EC2

 1. A Bastion server is created as SSH gateway server to master and slave EC2
 2. A master ec2 using autoscaling group for SSH connection, maintaining website files and admin
 3. A slave ec2 using autoscaling group for loading website files

## CloudFront

A cloudfront is created for S3 where website images are uploaded

## S3

S3 is mounted to master EC2 using S3FS

    s3fs#BUCKETNAME:/uploads /var/www/html/wp-content/uploads fuse _netdev,allow_other,iam_role,url=http://s3.amazonaws.com 0 0

A .htaccess with redirection to S3 image uploads should be created in Slave EC2

    RewriteEngine On
    RewriteRule ^wp-content/uploads/(.*)$ https://CLOUDFRONT-URL/uploads/$1 [R,L]
  
## RDS

RDS is used as database for Wordpress website

## EFS

EFS is mounted to Master EC2 and Slave EC2

    ${efspoint}':/ /var/www/html nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport 0 0
    

## Policies

    policy.json 
is used for S3 public read access for website image loading

    iam.json
is used for S3 bucket access to the IAM role which is then assigned to the WordpressMaster EC2 while creation

    backend.json
   is used for S3 access to backup the `terraform.tfstate` into the S3 bucket


## To Validate

 - ./terraform validate

## To Plan

 - ./terraform plan -var-file="terraform.tfvars"

## To Apply

 - ./terraform apply -var-file="terraform.tfvars" --auto-approve

## To apply using Backend

 - ./terraform init -backend-config="access_key=access-key" -backend-config="secret_key=secret-key"
