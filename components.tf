# Upload files to S3
resource "aws_s3_bucket_object" "component_files" {
  depends_on = [
    aws_s3_bucket.s3_pipeline_bucket,
    aws_kms_key.this
  ]

  for_each = fileset(path.module, "files/**/*.yml")

  bucket     = var.aws_s3_ami_resources_bucket
  key        = each.value
  source     = "${path.module}/${each.value}"
  kms_key_id = aws_kms_key.this.id
}

/* Add custom component resources below
 The YAML file referenced in the URI attribute must exist in the files/ directory
 Below is an example component. */
/* resource "aws_imagebuilder_component" "example_custom_component" {
  name       = "example-custom-component"
  platform   = "Linux"
  uri        = "s3://${var.aws_s3_ami_resources_bucket}/files/example-custom-component.yml"
  version    = "1.0.0"
  kms_key_id = aws_kms_key.this.arn

  depends_on = [
    aws_s3_bucket_object.component_files,
    aws_kms_key.this
  ]
} */