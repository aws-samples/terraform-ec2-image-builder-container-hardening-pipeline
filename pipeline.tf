# Create Pipeline S3 Bucket
resource "aws_s3_bucket" "s3_pipeline_bucket" {
  bucket = var.aws_s3_ami_resources_bucket
  tags = {
    Name = "${var.aws_s3_ami_resources_bucket}"
  }
  force_destroy = true
}

resource "aws_s3_bucket_acl" "s3_pipeline_bucket_acl" {
  bucket = aws_s3_bucket.s3_pipeline_bucket.id
  acl    = "private"
}

resource "aws_s3_bucket_policy" "allow_access_from_pipeline_service_role" {
  bucket = aws_s3_bucket.s3_pipeline_bucket.id
  policy = data.aws_iam_policy_document.allow_access_from_pipeline_service_role.json
}

resource "aws_s3_bucket_public_access_block" "s3_pipeline_bucket_block" {
  bucket = aws_s3_bucket.s3_pipeline_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "aws_iam_policy_document" "allow_access_from_pipeline_service_role" {
  statement {
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.account_id}:role/${var.hardening_pipeline_role_name}"]
    }

    actions = [
      "s3:PutObject",
      "s3:ListBucket",
      "s3:GetObject"
    ]

    resources = [
      aws_s3_bucket.s3_pipeline_bucket.arn,
      "${aws_s3_bucket.s3_pipeline_bucket.arn}/*",
    ]
  }
}

resource "aws_imagebuilder_image_pipeline" "this" {
  container_recipe_arn             = aws_imagebuilder_container_recipe.container_image.arn
  infrastructure_configuration_arn = aws_imagebuilder_infrastructure_configuration.this.arn
  name                             = var.image_name
  status                           = "ENABLED"
  description                      = "Creates images."
  distribution_configuration_arn   = aws_imagebuilder_distribution_configuration.this.arn

  schedule {
    schedule_expression = "cron(0 6 ? * fri)"
    # This cron expressions states every Friday at 6 AM.
    pipeline_execution_start_condition = "EXPRESSION_MATCH_AND_DEPENDENCY_UPDATES_AVAILABLE"
  }

  # Test the image after build
  image_tests_configuration {
    image_tests_enabled = true
  }

  tags = {
    "Name" = "${var.image_name}-hardening-container"
  }

  depends_on = [
    aws_imagebuilder_container_recipe.container_image,
    aws_imagebuilder_infrastructure_configuration.this,
    aws_imagebuilder_distribution_configuration.this,
  ]

  lifecycle {
    create_before_destroy = true
  }
}