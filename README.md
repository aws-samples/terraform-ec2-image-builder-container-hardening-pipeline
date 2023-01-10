# Terraform EC2 Image Builder Container Hardening Pipeline summary

Terraform modules build an [EC2 Image Builder Pipeline](https://docs.aws.amazon.com/imagebuilder/latest/userguide/start-build-image-pipeline.html) with an [Amazon Linux 2](https://aws.amazon.com/amazon-linux-2/) Baseline Container Recipe, which is used to deploy a [Docker](https://docs.docker.com/) based Amazon Linux 2 Container Image that has been hardened according to RHEL 7 STIG Version 3 Release 7 - Medium. See the “[STIG-Build-Linux-Medium version 2022.2.1](https://docs.aws.amazon.com/imagebuilder/latest/userguide/toe-stig.html#linux-os-stig)” section in Linux STIG Components for details. This is commonly referred to as a “Golden” container image.

The build includes two [Cloudwatch Event Rules](https://docs.aws.amazon.com/AmazonCloudWatch/latest/events/Create-CloudWatch-Events-Rule.html). One which triggers the start of the Container Image pipeline based on an [Inspector Finding](https://docs.aws.amazon.com/inspector/latest/user/findings-managing.html) of “High” or “Critical” so that insecure images are replaced, if Inspector and [Amazon Elastic Container Registry](https://docs.aws.amazon.com/AmazonECR/latest/userguide/repository-create.html) ["Enhanced Scanning"](https://docs.aws.amazon.com/AmazonECR/latest/userguide/image-scanning-enhanced.html) are both enabled. The other Event Rule sends notifications of a successful Image push to the ECR Repository to better enable consumption of new container images.

## Prerequisites

* Terraform v.15+. [Download](https://www.terraform.io/downloads.html) and setup Terraform. Refer to the official Terraform [instructions](https://learn.hashicorp.com/collections/terraform/aws-get-started) to get started.
* [AWS CLI installed](https://docs.aws.amazon.com/cli/v1/userguide/cli-chap-install.html) for setting your AWS Credentials for Local Deployment.
* [An AWS Account](https://aws.amazon.com/premiumsupport/knowledge-center/create-and-activate-aws-account/) to deploy the infrastructure within.
* [Git](https://git-scm.com/) (if provisioning from a local machine).
* A [role](https://www.google.com/url?sa=t&rct=j&q=&esrc=s&source=web&cd=&cad=rja&uact=8&ved=2ahUKEwjllPaT-LD8AhXsFFkFHd4PBEsQFnoECA8QAQ&url=https%3A%2F%2Fdocs.aws.amazon.com%2FIAM%2Flatest%2FUserGuide%2Fid_roles.html&usg=AOvVaw2x3qPB3Ld00_O0zMSxCNNi) within the AWS account that you are able create AWS resources with
* Ensure the [.tfvars](https://developer.hashicorp.com/terraform/tutorials/configuration-language/variables) file has all variables defined or define all variables at “Terraform Apply” time

## Target technology stack  

* Two [S3 Buckets](https://aws.amazon.com/s3/), 1 for the Pipeline [Component](https://docs.aws.amazon.com/imagebuilder/latest/userguide/create-component-console.html) Files and 1 for Server Access and VPC Flow logs
* An ECR [Repository](https://docs.aws.amazon.com/AmazonECR/latest/userguide/Repositories.html)
* A [VPC](https://aws.amazon.com/vpc/), a Public and Private [subnet](https://docs.aws.amazon.com/vpc/latest/userguide/configure-subnets.html), [Route tables](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Route_Tables.html), a [NAT Gateway](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-nat-gateway.html), and an [Internet Gateway](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Internet_Gateway.html)
* An EC2 Image Builder Pipeline, Recipe, and Components
* A Container Image
* A [KMS Key](https://www.google.com/url?sa=t&rct=j&q=&esrc=s&source=web&cd=&cad=rja&uact=8&ved=2ahUKEwiC5J339rD8AhV-F1kFHSp_CCEQFnoECA8QAQ&url=https%3A%2F%2Faws.amazon.com%2Fkms%2F&usg=AOvVaw3RCXPeRLWlWbJyXWU3HNGF) for Image Encryption
* An SQS Queue
* Three roles, one for the EC2 Image Builder Pipeline to execute as, one instance profile for EC2 Image Builder, and one for EventBridge Rules
* Two Cloudwatch Event Rules,  one which triggers the start of the pipeline based on an Inspector Finding of “High” or “Critical”, and one which sends notifications to an SQS Queue for a successful Image push to the ECR Repository
* This pattern creates 42 AWS Resources total

## Limitations 

[VPC Endpoints](https://docs.aws.amazon.com/whitepapers/latest/aws-privatelink/what-are-vpc-endpoints.html) cannot be used, and therefore this solution creates VPC Infrastructure that includes a [NAT Gateway](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-nat-gateway.html) and an Internet Gateway for internet connectivity from its private subnet. This is due to the bootstrap process by [AWSTOE](https://docs.aws.amazon.com/imagebuilder/latest/userguide/how-image-builder-works.html#ibhow-component-management), which installs AWS CLI v2 from the internet.

## Operating systems

This Pipeline only contains a recipe for Amazon Linux 2.

1. Amazon Linux 2

## Structure

``` console
├── pipeline.tf
├── image.tf
├── infr-config.tf
├── dist-config.tf
├── components.tf
├── recipes.tf
├── LICENSE
├── README.md
├── hardening-pipeline.tfvars
├── config.tf
├── files
│   └── assumption-policy.json
├── roles.tf
├── kms-key.tf
├── main.tf
├── outputs.tf
├── sec-groups.tf
└── variables.tf
```

## Module details

1. `hardening-pipeline.tfvars` contains the Terraform variables to be used at apply time
2. `pipeline.tf` creates and manages an EC2 Image Builder pipeline in Terraform
3. `image.tf` contains the definitions for the Base Image OS, this is where you can modify for a different base image pipeline.
4. `infr-config.tf` and `dist-config.tf`  contain the resources for the minimum AWS infrastructure needed to spin up and distribute the image.
5. `components.tf` contains an S3 upload resource to upload the contents of the /files directory, and where you can modularly add custom component YAML files as well.
6. `recipes.tf` is where you can specific different mixtures of components to create a different container recipe.
7. `trigger-build.tf` is an inspector2 finding based pipeline trigger.
8. `roles.tf` contains the IAM policy definitions for the EC2 Instance Profile and Pipeline Deployment Role
9. `infra-network-config.tf` contains the minimum VPC infrastructure to deploy the container image into
10. `/files` is intended to contain the `.yml` files which are used to define any custom components used in components.tf

## Target architecture
![Deployed Resources Architecture](container-harden.png)

## Automation and scale

* This terraform module set is intended to be used at scale. Instead of deploying it locally, the Terraform modules can be used in a multi-account strategy environment, such as in an [AWS Control Tower](https://docs.aws.amazon.com/controltower/latest/userguide/what-is-control-tower.html) with [Account Factory for Terraform](https://aws.amazon.com/blogs/aws/new-aws-control-tower-account-factory-for-terraform/) environment. In that case, a [backend state S3 bucket](https://developer.hashicorp.com/terraform/language/settings/backends/s3) should be used for managing Terraform state files, instead of managing the configuration state locally.

* To deploy for scaled use, deploy the solution to one central account, such as “Shared Services/Common Services” from a Control Tower or Landing Zone account model and grant consumer accounts permission to access to the ECR Repo/KMS Key, see [this blog post](https://aws.amazon.com/premiumsupport/knowledge-center/secondary-account-access-ecr/) explaining the setup. For example, in an [Account Vending Machine](https://www.hashicorp.com/resources/terraform-landing-zones-for-self-service-multi-aws-at-eventbrite) or Account Factory for Terraform, add permissions to each account baseline or account customization baseline to have access to that ECR Repo and Encryption key.

* This container image pipeline can be simply modified once deployed, using EC2 Image Builder features, such as the “Component” feature, which will allow easy packaging of more components into the Docker build.

* The KMS Key used to encrypt the container image should be shared across accounts which the container image is intended to be used in

* Support for other images can be added by simply duplicating this entire Terraform module, and modifying the `recipes.tf` attributes, `parent_image = "amazonlinux:latest"` to be another parent image type, and modifying the repository_name to point to an existing ECR repository. This will create another pipeline which deploys a different parent image type, but to your existing ECR repostiory.

## Deployment steps

### Local Deployment

1. Setup your AWS temporary credentials.

See if the AWS CLI is installed:
``` shell
   $ aws --version
   aws-cli/1.16.249 Python/3.6.8...
```

AWS CLI version 1.1 or higher is fine

If you instead got command not found then install the AWS CLI

2. Run aws configure and provide the following values:
``` shell
 $ aws configure
 AWS Access Key ID [*************xxxx]: <Your AWS Access Key ID>
 AWS Secret Access Key [**************xxxx]: <Your AWS Secret Access Key>
 Default region name: [us-east-1]: <Your desired region for deployment>
 Default output format [None]: <Your desired Output format>
```
3. Clone the repository with HTTPS or SSH

HTTPS
``` shell
git clone https://github.com/aws-samples/terraform-ec2-image-builder-container-hardening-pipeline.git
```
SSH
``` shell
git clone git@github.com:aws-samples/terraform-ec2-image-builder-container-hardening-pipeline.git
```
4. Navigate to the directory containing this solution before running the commands below:
``` shell
cd terraform-ec2-image-builder-container-hardening-pipeline
```

5. Update variables in hardening-pipeline.tfvars to match your environment and your desired configuration. You must provide your own `account_id`, however, you should modify the rest of the variables to fit your desired deployment.
``` json
account_id     = "<DEPLOYMENT-ACCOUNT-ID>"
aws_region     = "us-east-1"
vpc_name       = "example-hardening-pipeline-vpc"
kms_key_alias = "image-builder-container-key"
ec2_iam_role_name = "example-hardening-instance-role"
hardening_pipeline_role_name = "example-hardening-pipeline-role"
aws_s3_ami_resources_bucket = "example-hardening-ami-resources-bucket-0123"
image_name = "example-hardening-al2-container-image"
ecr_name = "example-hardening-container-repo"
recipe_version = "1.0.0" 
ebs_root_vol_size = 10
```

6. The following command initializes, validates and applies the terraform modules to the environment using the variables defined in your .tfvars file:
``` shell
terraform init && terraform validate && terraform apply -var-file *.tfvars -auto-approve
```

7. After successfully completion of your first Terraform apply, if provisioning locally, you should see this snippet in your local machine’s terminal:
``` shell
Apply complete! Resources: 42 added, 0 changed, 0 destroyed.
```

## Troubleshooting

When running Terraform apply or destroy commands from your local machine, you may encounter an error similar to the following:

``` json
Error: configuring Terraform AWS Provider: error validating provider credentials: error calling sts:GetCallerIdentity: operation error STS: GetCallerIdentity, https response error StatusCode: 403, RequestID: 123456a9-fbc1-40ed-b8d8-513d0133ba7f, api error InvalidClientTokenId: The security token included in the request is invalid.
```

This error is due to the expiration of the security token for the credentials used in your local machine’s configuration.

See “[Set and View Configuration Settings](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html#cli-configure-files-methods)” from the AWS Command Line Interface Documentation to resolve.

## Author

* Mike Saintcross [msaintcr@amazon.com](mailto:msaintcr@amazon.com)