###################################
## Base
###################################
variable "image_name" {
  type        = string
  description = "Enter the container's name."
  default     = "linux-baseline"

  validation {
    condition     = can(regex("[a-zA-Z0-9-]{3,50}", var.image_name))
    error_message = "The image_name value must be between 3 and 50 characters, should contain alphanumeric and hyphen characters only."
  }
}

variable "recipe_version" {
  type        = string
  description = "Enter the image recipe version. Example: 1.0.0"
}

variable "account_id" {
  type        = string
  description = "Enter the account number that you wish to deploy in."
}

variable "aws_region" {
  type        = string
  default     = "us-east-2"
  description = "Enter the AWS Region you wish to deploy in."
}

variable "vpc_name" {
  type        = string
  description = "Enter the name for your VPC infrastructure"
}

variable "ec2_iam_role_name" {
  type        = string
  description = "Enter the name for the role that will be used as the EC2 Instance Profile."
}

variable "hardening_pipeline_role_name" {
  type        = string
  description = "Enter the name for the role that will be used to deploy the hardening Pipeline."
}

variable "ecr_name" {
  type        = string
  description = "Enter the name for Elastic Container Registry to store the container images."
}

variable "aws_s3_ami_resources_bucket" {
  type        = string
  description = "Enter the name for an S3 Bucket that will host all files necessary to build the pipeline and container images."
}

variable "ebs_root_vol_size" {
  type        = number
  description = "Enter the size (in gigabytes) of the EBS Root Volume."
}

variable "kms_key_alias" {
  type        = string
  description = "Enter the KMS Key name to be used by the image builder infrastructure configuration."
}