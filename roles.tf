resource "aws_iam_role" "ec2_iam_role" {
  name               = var.ec2_iam_role_name
  assume_role_policy = file("files/assumption-policy.json")
  inline_policy {
    name = "hardening_instance_inline_policy"
    policy = jsonencode({
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : [
            "ssm:DescribeAssociation",
            "ssm:GetDeployablePatchSnapshotForInstance",
            "ssm:GetDocument",
            "ssm:DescribeDocument",
            "ssm:GetManifest",
            "ssm:GetParameter",
            "ssm:GetParameters",
            "ssm:ListAssociations",
            "ssm:ListInstanceAssociations",
            "ssm:PutInventory",
            "ssm:PutComplianceItems",
            "ssm:PutConfigurePackageResult",
            "ssm:UpdateAssociationStatus",
            "ssm:UpdateInstanceAssociationStatus",
            "ssm:UpdateInstanceInformation",
            "ssmmessages:CreateControlChannel",
            "ssmmessages:CreateDataChannel",
            "ssmmessages:OpenControlChannel",
            "ssmmessages:OpenDataChannel",
            "ec2messages:AcknowledgeMessage",
            "ec2messages:DeleteMessage",
            "ec2messages:FailMessage",
            "ec2messages:GetEndpoint",
            "ec2messages:GetMessages",
            "ec2messages:SendReply",
            "ec2:CreateTags",
            "imagebuilder:GetComponent",
            "imagebuilder:GetContainerRecipe",
            "ecr:GetAuthorizationToken",
            "ecr:BatchGetImage",
            "ecr:InitiateLayerUpload",
            "ecr:UploadLayerPart",
            "ecr:CompleteLayerUpload",
            "ecr:BatchCheckLayerAvailability",
            "ecr:GetDownloadUrlForLayer",
            "ecr:PutImage"
          ],
          "Resource" : [
            "*"
          ]
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "s3:List*",
            "s3:GetObject",
            "S3:GetBucketPolicy",
            "S3:PutBucketPolicy"
          ],
          "Resource" : [
            "*"
          ]
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "s3:PutObject"
          ],
          "Resource" : [
            "arn:aws:s3:::${var.aws_s3_ami_resources_bucket}/image-builder/*"
          ]
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "logs:CreateLogStream",
            "logs:CreateLogGroup",
            "logs:PutLogEvents"
          ],
          "Resource" : [
            "arn:aws:logs:*:*:log-group:/aws/imagebuilder/*"
          ]
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "kms:Decrypt"
          ],
          "Resource" : [
            "*"
          ],
          "Condition" : {
            "ForAnyValue:StringEquals" : {
              "kms:EncryptionContextKeys" : "aws:imagebuilder:arn"
            }
          }
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "s3:GetObject"
          ],
          "Resource" : [
            "arn:aws:s3:::ec2imagebuilder*"
          ]
        },
        {
          "Sid" : "Ec2ImageBuilderCrossAccountDistributionAccessTags",
          "Effect" : "Allow",
          "Action" : [
            "ec2:CreateTags"
          ],
          "Resource" : [
            "arn:aws:ec2:*::image/*"
          ]
        },
        {
          "Sid" : "Ec2ImageBuilderCrossAccountDistributionAccess",
          "Effect" : "Allow",
          "Action" : [
            "ec2:DescribeImages",
            "ec2:CopyImage",
            "ec2:ModifyImageAttribute"
          ],
          "Resource" : [
            "*"
          ]
        },
        {
          "Effect" : "Allow",
          "Action" : "inspector2:*",
          "Resource" : "*"
        },
        {
          "Effect" : "Allow",
          "Action" : "iam:CreateServiceLinkedRole",
          "Resource" : "*",
          "Condition" : {
            "StringEquals" : {
              "iam:AWSServiceName" : "inspector2.amazonaws.com"
            }
          }
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "organizations:EnableAWSServiceAccess",
            "organizations:RegisterDelegatedAdministrator",
            "organizations:ListDelegatedAdministrators",
            "organizations:ListAWSServiceAccessForOrganization",
            "organizations:DescribeOrganizationalUnit",
            "organizations:DescribeAccount",
            "organizations:DescribeOrganization"
          ],
          "Resource" : "*"
        }
      ]
    })
  }
}

# Create the EC2 Instance Profile to use for the image
resource "aws_iam_instance_profile" "image_builder_role" {
  name = var.ec2_iam_role_name
  role = aws_iam_role.ec2_iam_role.name
}

resource "aws_iam_role" "hardening_pipeline_role" {
  name               = var.hardening_pipeline_role_name
  assume_role_policy = file("files/assumption-policy.json")
  inline_policy {
    name = "hardening_pipeline_inline_policy"
    policy = jsonencode({
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Sid" : "VisualEditor0",
          "Effect" : "Allow",
          "Action" : [
            "events:DescribeRule",
            "kms:Decrypt",
            "kms:TagResource",
            "kms:Encrypt",
            "ec2:CreateSecurityGroup",
            "ec2:CreateTags",
            "ec2:RevokeSecurityGroupEgress",
            "ec2:AuthorizeSecurityGroupEgress",
            "events:PutRule",
            "kms:GenerateDataKey",
            "kms:CreateAlias",
            "kms:DescribeKey",
            "kms:DeleteAlias",
            "kms:GenerateDataKeyPair"
          ],
          "Resource" : [
            "arn:aws:ec2:*:${var.account_id}:security-group/*",
            "arn:aws:ec2:*:${var.account_id}:vpc/*",
            "arn:aws:events:*:${var.account_id}:rule/*",
            "arn:aws:kms:*:${var.account_id}:key/*",
            "arn:aws:kms:*:${var.account_id}:alias/*"
          ]
        },
        {
          "Sid" : "VisualEditor1",
          "Effect" : "Allow",
          "Action" : [
            "iam:GetRole",
            "iam:CreateGroup",
            "iam:ListAttachedRolePolicies",
            "iam:CreateRole",
            "iam:PutRolePolicy",
            "iam:ListRolePolicies",
            "iam:GetRolePolicy",
            "iam:GetInstanceProfile",
            "iam:CreateInstanceProfile",
            "iam:RemoveRoleFromInstanceProfile",
            "iam:DeleteInstanceProfile",
            "iam:AddRoleToInstanceProfile"
          ],
          "Resource" : [
            "arn:aws:iam::${var.account_id}:group/*",
            "arn:aws:iam::${var.account_id}:role/*",
            "arn:aws:iam::${var.account_id}:instance-profile/${var.ec2_iam_role_name}"
          ]
        },
        {
          "Sid" : "VisualEditor2",
          "Effect" : "Allow",
          "Action" : [
            "kms:ListKeys",
            "kms:ListAliases",
            "kms:CreateKey"
          ],
          "Resource" : "*"
        }
      ]
    })
  }
}