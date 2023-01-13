locals {
  core_tags = {
    ManagedBy = "Terraform"
  }

  # These can be leveraged to customize your deployment.
  kms_admin_role_name = var.hardening_pipeline_role_name
  ecr_name            = var.ecr_name
}

data "aws_caller_identity" "current" {}