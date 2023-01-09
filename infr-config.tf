resource "aws_imagebuilder_infrastructure_configuration" "this" {
  description                   = "Container Image Infrastructure configuration"
  instance_profile_name         = var.ec2_iam_role_name
  instance_types                = ["t3.micro"]
  name                          = "${var.image_name}-infr"
  security_group_ids            = [aws_security_group.image_builder_sg.id]
  subnet_id                     = aws_subnet.hardening_pipeline_private.id
  terminate_instance_on_failure = true

  logging {
    s3_logs {
      s3_bucket_name = var.aws_s3_ami_resources_bucket
      s3_key_prefix  = "image-builder/"
    }
  }

  tags = local.core_tags
}