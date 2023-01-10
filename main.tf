###################################
## Main
###################################

locals {
  core_tags = {
    ManagedBy = "Terraform"
  }

  account_id          = data.aws_caller_identity.current.account_id
  kms_admin_role_name = var.hardening_pipeline_role_name
  ecr_name            = var.ecr_name
}

data "aws_caller_identity" "current" {}