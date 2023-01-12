# Upload files to S3
resource "aws_s3_bucket_object" "component_files" {
  depends_on = [
    aws_s3_bucket.s3_pipeline_bucket
  ]

  for_each = fileset(path.module, "files/**/*.yml")

  bucket                 = var.aws_s3_ami_resources_bucket
  key                    = each.value
  source                 = "${path.module}/${each.value}"
  server_side_encryption = "aws:kms"
}

# Add custom component resources below