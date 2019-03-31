# terraform-aws-certbot-cloudflare-lambda

[![Latest Release](https://img.shields.io/github/release/robertpeteuil/terraform-aws-certbot-cloudflare-lambda.svg)](https://github.com/robertpeteuil/terraform-aws-certbot-cloudflare-lambda) [![license](https://img.shields.io/github/license/robertpeteuil/terraform-aws-certbot-cloudflare-lambda.svg?colorB=2067b8)](https://github.com/robertpeteuil/terraform-aws-certbot-cloudflare-lambda)

`terraform-aws-certbot-cloudflare-lambda` is a Terraform module to provision a Lambda Function which obtains & renews LetsEncrypt Certificates for domains using Cloudflare DNS.

## Terraform Module Features

This Module allows simple and rapid deployment

- Creates Lambda function, Lambda Layer, IAM Policies, Triggers, and Subscriptions
- Uses specified S3 Bucket/Key for encrypted storage of Cloudflare API credentials and retrieved SSL Certificates.
- Create CloudWatch Event to trigger function to renew certificates
- Python function editable in repository and in Lambda UI
- Python dependencies packages in Lambda Layers zip
  - Optionally create custom Lambda Layer zip using [build-lambda-layer-python](https://github.com/robertpeteuil/build-lambda-layer-python)
    - Enables adding/changing dependencies
    - Enables compiling for different version of Python

## Certbot Cloudflare Features

This Lambda Function generates & renews SSL Certificates from LetsEncrypt for domains using Cloudflare DNS and stores the in an encrypted S3 bucket

- Provides host independant creation and renewal of LetsEncrypt certificates
  - separates certificate generation/renewal process from host
- Allow provisioned host bootstrap to retrieve latest SSL keys from S3 bucket
- Retrieves Cloudflare Credentials file from encrypted S3 storage
  - Module will generate file if Cloudflare credentials are provided as vars
  - Otherwise file can be manually created and uploaded to S3
  - Credentials file location `$s3_bucket/$s3_path/dns/cloudflare.ini`
- SSL Certificates are stored at location: `$s3_bucket/$s3_path/live/`
- Supports optionally logging to SNS Topic
  - SNS Topic can be routed to CloudWatch Log group with [SNS to CloudWatch](https://github.com/robertpeteuil/terraform-aws-sns-to-cloudwatch-logs-lambda) module
- Four digit random number appended to name to allow multiple functions to run in same AWS region (to support multiple domains)

## Usage

The module authenticates to the cloudflare DNS by retrieving a Cloudflare Credentials file from S3.  This file can be generated by the module, or manually created an placed at the correct location.

Using the Module with optional `cloudflare` params to generate and upload Cloudflare credential file to S3.

``` ruby
module "certbot_example" {
  source            = "robertpeteuil/certbot-cloudflare-lambda/aws"
  version           = "1.0.0"

  aws_region           = "us-west-2"
  letsencrypt_domains  = "example.com,www.example.com"
  letsencrypt_email    = "me@example.com"
  s3_bucket            = "projectx"
  s3_path              = "certs"

  # optional if file is manually created
  cloudflare_api_key   = "key-654654a54c465c87d87f87fg6"
  cloudflare_email     = "mycloudflareemail@domain.com"
}
```

The file can be manually created as a text file in the format below and uploaded to the location: `$s3_bucket/$s3_path/dns/cloudflare.ini`

``` ini
dns_cloudflare_email = mycloudflareemail@domain.com
dns_cloudflare_api_key = key-654654a54c465c87d87f87fg6
```

> NOTE: Make sure you are using [version pinning](https://www.terraform.io/docs/modules/usage.html#module-versions) to avoid unexpected changes when the module is updated.

## Required Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| aws_region | Region where AWS resources are located | string | - | yes |
| letsencrypt_domains | Domain to get/renew certificates | string | - | yes |
| letsencrypt_email | Email to use with LetsEncrypt  | string | - | yes |
| s3_bucket | S3 Bucket where config and keys are stored | string | - | yes |
| s3_path | S3 Path where config and keys are stored | string | - | yes |

## Optional Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| cloudflare_api_key | Cloudflare API Key | string | `` | no |
| cloudflare_email | Cloudflare Email Address | string | `` | no |
| sns_topic | SNS Topic name used for logging | string | `` | no |
| get_test_cert | Request Test certs | string | `false` | no |
| lambda_tags | Mapping of Tags to assign to Lambda function | map | `{}` | no |
| lambda_func_name | Name for Lambda Function | string | `Certbot-Cloudflare` | no |
| lambda_description | Lambda Function Description | string | `LetsEncrypts Cert Manager for Cloudflare Domains` | no |
| lambda_publish_func | Publish Lambda Function | string | `false` | no |
| create_sched_event | Create event trigger to renew certs | string | `true` | no |
| lambda_runtime | Lambda runtime for Function | string | `python3.6` | no |
| lambda_timeout | Function time-out (seconds) | string | `120` | no |
| lambda_mem_size | Function RAM assigned (MB) | string | `128` | no |