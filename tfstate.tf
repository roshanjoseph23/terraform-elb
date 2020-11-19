terraform {
  backend "s3" {
    bucket         = "<bucketname>"
    key            = "test/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = 
  }
}
