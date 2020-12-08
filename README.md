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

## Prerequisites

 - An IAM user with programmatic access with AWS Admin permission needs to be created.
 - Key pair needs to be created for SSH to Bastion server
 - An S3 needs to be created to backup tfstate

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

S3 is moounted to master EC2 using S3FS
A .htaccess with redirection to S3 image uploads should be created in Slave EC2

    RewriteEngine On
    RewriteRule ^wp-content/uploads/(.*)$ https://CLOUDFRONT-URL/uploads/$1 [R,L]
  
## RDS

RDS is used as database for Wordpress website

## EFS

EFS is mounted to Master EC2 and Slave EC2

## To Validate

 - ./terraform validate -var-file="terraform.tfvars"

## To Plan

 - ./terraform plan -var-file="terraform.tfvars"

## To Apply

 - ./terraform apply -var-file="terraform.tfvars" --auto-approve

## To apply using Backend

 - ./terraform init -backend-config="access_key=access-key" -backend-config="secret_key=secret-key"
