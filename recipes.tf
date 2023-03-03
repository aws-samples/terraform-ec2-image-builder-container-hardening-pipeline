resource "aws_imagebuilder_container_recipe" "container_image" {

  depends_on = [
    aws_ecr_repository.hardening_pipeline_repo
  ]

  name    = var.image_name
  version = "1.0.0"

  container_type    = "DOCKER"
  parent_image      = "amazonlinux:latest"
  working_directory = "/build"

  target_repository {
    repository_name = var.ecr_name
    service         = "ECR"
  }

  instance_configuration {

    block_device_mapping {
      device_name = "/dev/xvdb"

      ebs {
        delete_on_termination = true
        volume_size           = var.ebs_root_vol_size
        volume_type           = "gp3"
        encrypted             = true
        kms_key_id            = aws_kms_key.this.arn
      }
    }

  }

  component {
    component_arn = "arn:aws:imagebuilder:${var.aws_region}:aws:component/update-linux/x.x.x"
  }

  component {
    component_arn = "arn:aws:imagebuilder:${var.aws_region}:aws:component/stig-build-linux-medium/x.x.x"
  }

  # Add more component ARNs here to customize the recipe
  # You can also add custom components if you defined any in components.tf
  /* component {
    component_arn = aws_imagebuilder_component.example_custom_component.arn
  } */

  dockerfile_template_data = <<EOF
FROM {{{ imagebuilder:parentImage }}}
{{{ imagebuilder:environments }}}
{{{ imagebuilder:components }}}
EOF
}