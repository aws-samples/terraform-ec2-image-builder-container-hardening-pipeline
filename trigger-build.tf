resource "aws_sqs_queue" "container_build_queue" {
  name                      = "hardened-container-build-queue"
  sqs_managed_sse_enabled   = true
  delay_seconds             = 90
  max_message_size          = 2048
  message_retention_seconds = 86400
  receive_wait_time_seconds = 10
}

resource "aws_cloudwatch_event_rule" "new_image_push" {
  name        = "new-hardened-container-build-push"
  description = "New hardened container image successful push event rule."

  event_pattern = <<EOF
{
  "source": ["aws.ecr"],
  "detail-type": ["ECR Image Action"],
  "detail": {
    "action-type": ["PUSH"],
    "result": ["SUCCESS"],
    "repository-name": ["${var.ecr_name}"]
  }
}
EOF
}

resource "aws_cloudwatch_event_target" "sqs_queue" {
  rule      = aws_cloudwatch_event_rule.new_image_push.name
  target_id = "NewContainerBuild"
  arn       = aws_sqs_queue.container_build_queue.arn
}

data "aws_iam_policy_document" "trigger_role_policy" {
  statement {
    sid     = "STSRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com", ]
    }
  }
}

resource "aws_sqs_queue_policy" "sqs_policy" {
  queue_url = aws_sqs_queue.container_build_queue.id

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "sqsPolicy",
  "Statement": [
    {
      "Sid": "First",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "sqs:SendMessage",
      "Resource": "${aws_sqs_queue.container_build_queue.arn}",
      "Condition": {
        "ArnEquals": {
          "aws:SourceArn": "arn:aws:events:${var.aws_region}:${var.account_id}:rule/${aws_cloudwatch_event_rule.new_image_push.name}"
        }
      }
    }
  ]
}
POLICY
}

resource "aws_iam_role" "trigger_role" {
  name               = "${var.ec2_iam_role_name}-eb-trigger-role"
  assume_role_policy = data.aws_iam_policy_document.trigger_role_policy.json
}

resource "aws_cloudwatch_event_rule" "inspector_finding" {
  name        = "hardening-image-build"
  description = "Trigger hardening Image Re-Build on High or Critical Severity Findings"

  event_pattern = <<EOF
{
  "source": ["aws.inspector2"],
  "detail-type": ["Inspector2 Finding"],
  "detail": {
    "severity": [{ "anything-but": [ "LOW", "MEDIUM" ] }]
  }
}
EOF
}

resource "aws_cloudwatch_event_target" "container_pipeline" {
  rule      = aws_cloudwatch_event_rule.inspector_finding.name
  target_id = "StartContainerBuild"
  arn       = aws_imagebuilder_image_pipeline.this.arn
  role_arn  = aws_iam_role.trigger_role.arn
}