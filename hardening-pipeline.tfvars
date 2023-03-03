# Enter values for all of the following if you wish to avoid being prompted on each run.
account_id                   = "063449332233"
aws_region                   = "us-west-2"
vpc_name                     = "example-hardening-pipeline-vpc"
kms_key_alias                = "image-builder-container-key-2"
ec2_iam_role_name            = "example-hardening-instance-role"
hardening_pipeline_role_name = "example-hardening-pipeline-role"
aws_s3_ami_resources_bucket  = "example-hardening-ami-resources-bucket-012345"
image_name                   = "example-hardening-al2-container-image"
ecr_name                     = "example-hardening-container-repo"
recipe_version               = "1.0.0"
ebs_root_vol_size            = 10