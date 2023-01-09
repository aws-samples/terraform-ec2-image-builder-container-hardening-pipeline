resource "aws_iam_role" "trigger_role" {
  name = "${var.ec2_iam_role_name}-event-bridge-role"
  assume_role_policy = <<DOC
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "events.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
DOC
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