
################################ we can define variables here#####################################
variable "region" {
  type        = string
  description = "The AWS region to deploy resources"
  default     = "us-east-1"
}

variable "bucket" {
  type        = string
  description = "The name of the S3 bucket"
  default     = "venu_hcl_hackthon"
}

