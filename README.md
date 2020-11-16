This is to creat an infrastructure for a High Availability wordpress website which uses Application Load Balancer with AutoScaling.
Uses RDS as Database
Uses S3 as Wordpress image uploads storage
Uses Bastion server as gateway with custom VPC
Uses EFS for wordpress files
Uses userdata to mount EFS and S3

S3 is moounted to master EC2 using S3FS, for Slave EC2 need to create a .htaccess file with redirection set to S3.


# TO VALIDATE
./terraform validate -var-file="terraform.tfvars"

# TO PLAN
./terraform plan -var-file="terraform.tfvars"

# TO APPLY
./terraform apply -var-file="terraform.tfvars" --auto-approve
