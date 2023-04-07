# Terraform EC2 Image Builder Container Hardening Pipeline summary

This pattern builds an [EC2 Image Builder pipeline](https://docs.aws.amazon.com/imagebuilder/latest/userguide/start-build-image-pipeline.html) that produces a hardened [Amazon Linux 2](https://aws.amazon.com/amazon-linux-2/) base container image. Terraform is used as an infrastructure as code (IaC) tool to configure and provision the infrastructure that is used to create hardened container images. The recipe helps you deploy a [Docker](https://docs.docker.com/)-based Amazon Linux 2 container image that has been hardened according to Red Hat Enterprise Linux (RHEL) 7 STIG Version 3 Release 7 ‒ Medium. (See [STIG-Build-Linux-Medium version 2022.2.1](https://docs.aws.amazon.com/imagebuilder/latest/userguide/toe-stig.html#linux-os-stig) in the _Linux STIG components_ section of the EC2 Image Builder documentation.) This is commonly referred to as a _golden_ container image.  
  
The build includes two Amazon [EventBridge rules](https://docs.aws.amazon.com/eventbridge/latest/userguide/eb-rules.html). One rule starts the container image pipeline when the Amazon [Inspector finding](https://docs.aws.amazon.com/inspector/latest/user/findings-managing.html) is **High** or **Critical** so that non-secure images are replaced. (This rule requires both Amazon Inspector and Amazon Elastic Container Registry (Amazon ECR) [enhanced scanning](https://docs.aws.amazon.com/AmazonECR/latest/userguide/image-scanning-enhanced.html) to be enabled.) The other rule sends notifications to an Amazon Simple Queue Service (Amazon SQS) [queue](https://aws.amazon.com/sqs/) after a successful image push to the Amazon ECR repository, to help you use the latest container images.

In January 2023, [EC2 Image Builder added support for AWS Marketplace CIS Pre-Hardened images](https://aws.amazon.com/about-aws/whats-new/2023/01/ec2-image-builder-cis-benchmarks-security-hardening-amis/). This achieves a hardening goal, but is only for AMIs, not Container images, and you must sign-up for a [subscription](https://aws.amazon.com/marketplace/seller-profile?id=dfa1e6a8-0b7b-4d35-a59c-ce272caee4fc) in [AWS Marketplace](https://aws.amazon.com/marketplace) to CIS.

## Prerequisites

- An [AWS account](https://aws.amazon.com/premiumsupport/knowledge-center/create-and-activate-aws-account/) that you can deploy the infrastructure in.
- [AWS Command Line Interface (AWS CLI) installed](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) for setting your AWS credentials for local deployment.
- [Download](https://developer.hashicorp.com/terraform/downloads) and set up Terraform by following the [instructions](https://developer.hashicorp.com/terraform/tutorials/aws-get-started) in the Terraform documentation.
- [Git](https://git-scm.com/) (if you’re provisioning from a local machine).
-  A [role](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles.html) within the AWS account that you can use to create AWS resources.
-  All variables defined in the [.tfvars](https://developer.hashicorp.com/terraform/tutorials/configuration-language/variables) file.  Or, you can define all variables when you apply the Terraform configuration.

## Limitations

-   This solution creates an Amazon Virtual Private Cloud (Amazon VPC) infrastructure that includes a [NAT gateway](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-nat-gateway.html) and an [internet gateway](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Internet_Gateway.html) for internet connectivity from its private subnet. You cannot use [VPC endpoints](https://docs.aws.amazon.com/whitepapers/latest/aws-privatelink/what-are-vpc-endpoints.html), because the [bootstrap process by AWS Task Orchestrator and Executor (AWSTOE](https://aws.amazon.com/premiumsupport/knowledge-center/image-builder-pipeline-execution-error/)) installs AWS CLI version 2 from the internet.

## Product versions

- Amazon Linux 2
- AWS CLI version 1.1 or later

## Target technology stack

This pattern creates 43 resources, including:

- Two Amazon Simple Storage Service (Amazon S3) [buckets](https://aws.amazon.com/s3/): one for the pipeline component files and one for server access and Amazon VPC flow logs
- An [Amazon ECR repository](https://docs.aws.amazon.com/AmazonECR/latest/userguide/repository-create.html)
- A virtual private cloud (VPC) that contains a public subnet, a private subnet, route tables, a NAT gateway, and an internet gateway
-  An EC2 Image Builder pipeline, recipe, and components
-  A container image
- An AWS Key Management Service (AWS KMS) [key](https://www.google.com/url?sa=t&rct=j&q=&esrc=s&source=web&cd=&cad=rja&uact=8&ved=2ahUKEwiC5J339rD8AhV-F1kFHSp_CCEQFnoECA8QAQ&url=https%3A%2F%2Faws.amazon.com%2Fkms%2F&usg=AOvVaw3RCXPeRLWlWbJyXWU3HNGF) for image encryption
- An SQS queue
- Three roles: one to run the EC2 Image Builder pipeline, one instance profile for EC2 Image Builder, and one for Amazon EventBridge rules
- Two Amazon EventBridge rules

## Structure

``` console
├── components.tf
├── config.tf
├── dist-config.tf
├── files
│   └──assumption-policy.json
├── hardening-pipeline.tfvars
├── image.tf
├── infr-config.tf
├── infra-network-config.tf
├── kms-key.tf
├── main.tf
├── outputs.tf
├── pipeline.tf
├── recipes.tf
├── roles.tf
├── sec-groups.tf
├── trigger-build.tf
└── variables.tf
```

## Module details

- components.tf contains an Amazon S3 upload resource to upload the contents of the /files directory. You can also modularly add custom component YAML files here as well.
- /files contains the .yml files that define the components used in components.tf.
- image.tf contains the definitions for the base image operating system. This is where you can modify the definitions for a different base image pipeline.
- infr-config.tf and dist-config.tf contain the resources for the minimum AWS infrastructure needed to spin up and distribute the image.
- infra-network-config.tf contains the minimum VPC infrastructure to deploy the container image into.
- hardening-pipeline.tfvars contains the Terraform variables to be used at apply time.
- pipeline.tf creates and manages an EC2 Image Builder pipeline in Terraform.
- recipes.tf is where you can specify different mixtures of components to create container recipes.
- roles.tf contains the AWS Identity and Access Management (IAM) policy definitions for the Amazon Elastic Compute Cloud (Amazon EC2) instance profile and pipeline deployment role.
- trigger-build.tf contains the EventBridge rules and SQS queue resources.

## Target architecture

![Deployed Resources Architecture](container-harden.png)

The diagram illustrates the following workflow:

1. EC2 Image Builder builds a container image by using the defined recipe, which installs operating system updates and applies the RHEL Medium STIG to the Amazon Linux 2 base image.
2. The hardened image is published to a private Amazon ECR registry, and an EventBridge rule sends a message to an SQS queue when the image has been published successfully.
3. If Amazon Inspector is configured for enhanced scanning, it scans the Amazon ECR registry.
4. If Amazon Inspector generates a **Critical** or **High** severity finding for the image, an EventBridge rule triggers the EC2 Image Builder pipeline to run again and publish a newly hardened image.

## Automation and scale

- This pattern describes how to provision the infrastructure and build the pipeline on your computer. However, it is intended to be used at scale. Instead of deploying the Terraform modules locally, you can use them in a multi-account environment, such as an [AWS Control Tower](https://docs.aws.amazon.com/controltower/latest/userguide/what-is-control-tower.html) with [Account Factory for Terraform](https://aws.amazon.com/blogs/aws/new-aws-control-tower-account-factory-for-terraform/) environment. In that case, you should use [a backend state S3 bucket](https://developer.hashicorp.com/terraform/language/settings/backends/s3) to manage Terraform state files, instead of managing the configuration state locally.
- For scaled use, deploy the solution to one central account, such as a Shared Services or Common Services account, from a Control Tower or landing zone account model, and grant consumer accounts permission to access the Amazon ECR repository and AWS KMS key. For more information about the setup, see the re:Post article [How can I allow a secondary account to push or pull images in my Amazon ECR image repository?](https://repost.aws/knowledge-center/secondary-account-access-ecr) For example, in an [account vending machine](https://www.hashicorp.com/resources/terraform-landing-zones-for-self-service-multi-aws-at-eventbrite) or Account Factory for Terraform, add permissions to each account baseline or account customization baseline to provide access to that Amazon ECR repository and encryption key.
- After the container image pipeline is deployed, you can modify it by using EC2 Image Builder features such as [components](https://docs.aws.amazon.com/imagebuilder/latest/userguide/manage-components.html), which help you package more components into the Docker build.
- The AWS KMS key that is used to encrypt the container image should be shared across the accounts that the image is intended to be used in.
- You can add support for other images by duplicating the entire Terraform module and modifying the following recipes.tf attributes:
- Modify `parent_image = "amazonlinux:latest"` to another image type.
- Modify `repository_name` to point to an existing Amazon ECR repository. This creates another pipeline that deploys a different parent image type to your existing Amazon ECR repository.

## Tools

-   Terraform (IaC provisioning)
-   Git (if provisioning locally)
-   AWS CLI version 1 or version 2 (if provisioning locally)

## Deployment steps

### Local Deployment

1. Setup your AWS temporary credentials.

   See if the AWS CLI is installed: 

``` bash
   $ aws --version
   aws-cli/1.16.249 Python/3.6.8...
```

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;AWS CLI version 1.1 or higher is fine.

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;If you instead received `command not found` then install the AWS CLI.

2. Run aws configure and provide the following values:
``` bash
 $ aws configure
 AWS Access Key ID [*************xxxx]: <Your AWS Access Key ID>
 AWS Secret Access Key [**************xxxx]: <Your AWS Secret Access Key>
 Default region name: [us-east-1]: <Your desired region for deployment>
 Default output format [None]: <Your desired Output format>
```
3. Clone the repository with HTTPS or SSH

   _HTTPS_
``` bash
git clone https://github.com/aws-samples/terraform-ec2-image-builder-container-hardening-pipeline.git
```
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;_SSH_

``` bash
git clone git@github.com:aws-samples/terraform-ec2-image-builder-container-hardening-pipeline.git
```
4. Navigate to the directory containing this solution before running the commands below:
``` bash
cd terraform-ec2-image-builder-container-hardening-pipeline
```

5. Update the placeholder variable values in hardening-pipeline.tfvars. You must provide your own `account_id`, `kms_key_alias`, and `aws_s3_ami_resources_bucket`, however, you should also modify the rest of the placeholder variables to match your environment and your desired configuration. 
``` properties
account_id                   = "<DEPLOYMENT-ACCOUNT-ID>"
aws_region                   = "us-east-1"
vpc_name                     = "example-hardening-pipeline-vpc"
kms_key_alias                = "image-builder-container-key"
ec2_iam_role_name            = "example-hardening-instance-role"
hardening_pipeline_role_name = "example-hardening-pipeline-role"
aws_s3_ami_resources_bucket  = "example-hardening-ami-resources-bucket-name"
image_name                   = "example-hardening-al2-container-image"
ecr_name                     = "example-hardening-container-repo"
recipe_version               = "1.0.0" 
ebs_root_vol_size            = 10
```

6. The following command initializes, validates and applies the terraform modules to the environment using the variables defined in your .tfvars file:
``` bash
terraform init && terraform validate && terraform apply -var-file *.tfvars -auto-approve
```

7. After successful completion of your first Terraform apply, if provisioning locally, you should see this snippet in your local machine’s terminal:
``` bash
Apply complete! Resources: 43 added, 0 changed, 0 destroyed.
```

8. *(Optional)* Teardown the infrastructure with the following command:
``` bash
terraform init && terraform validate && terraform destroy -var-file *.tfvars -auto-approve
```

## Troubleshooting

When running Terraform apply or destroy commands from your local machine, you may encounter an error similar to the following:

``` properties
Error: configuring Terraform AWS Provider: error validating provider credentials: error calling sts:GetCallerIdentity: operation error STS: GetCallerIdentity, https response error StatusCode: 403, RequestID: 123456a9-fbc1-40ed-b8d8-513d0133ba7f, api error InvalidClientTokenId: The security token included in the request is invalid.
```

This error is due to the expiration of the security token for the credentials used in your local machine’s configuration.

See "[Set and View Configuration Settings](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html#cli-configure-files-methods)" from the AWS Command Line Interface Documentation to resolve.

## Author

* Mike Saintcross [@msntx](https://github.com/msntx)