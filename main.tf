provider "aws" {
region = "var.region"   
}

resource "aws_s3_bucket" "bucket" {
  bucket = "my-terraform-backend-bucket"
}

resource "aws_dynamodb_table" "lock_table" {
  name         = "my-terraform-lock-table"
  hash_key     = "LockID"
  billing_mode = "PAY_PER_REQUEST"
  attribute {
    name = "LockID"
    type = "S"
  }
}


terraform {
  backend "s3" {
    bucket         = "my-terraform-backend-bucket"    # S3 Bucket Name
    key            = "path/to/my/terraform.tfstate"   # Path in S3 where state is stored
    region         = "us-east-1"                       # AWS Region
    encrypt        = true                              # Enable encryption of state file
    dynamodb_table = "my-terraform-lock-table"        # DynamoDB Table for state locking
    
  }
}

