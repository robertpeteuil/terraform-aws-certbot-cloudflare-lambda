# -----------------------------------------------------------------
# REQUIRED VARIABLES WITHOUT DEFAULT VALUES
# -----------------------------------------------------------------

variable "aws_region" {
  description = "Region where AWS resources will be created and used."
}

variable "letsencrypt_domains" {
  description = "Domain to get/renew SSL certificate from LetsEncrypt."
}

variable "letsencrypt_email" {
  description = "Email to use to get/renewl SSL certificate from LetsEncrypt."
}

variable "s3_bucket" {
  description = "S3 Bucket where config and keys are stored."
}

variable "s3_path" {
  description = "S3 Path where config and keys are stored."
}

# -----------------------------------------------------------------
# VARIABLES DEFINITIONS WITH DEFAULT VALUES
# -----------------------------------------------------------------

variable "cloudflare_api_token" {
  description = "Cloudflare API token.  If set - Terraform creates the credential file and uploads it to S3 for use by Lambda Function.  If not set - credential file must be created and manually placed in S3."
  default     = ""
}

variable "sns_topic" {
  description = "SNS Topic name used for logging"
  default     = ""
}

variable "get_test_cert" {
  default     = "False"
  description = "Flag that determines if test certificates requested."
}

variable "lambda_tags" {
  description = "A mapping of tags to assign to Lambda Function."
  default     = {}
}

# -----------------------------------------------------------------
# LAMBDA FUNCTION
# -----------------------------------------------------------------

variable "lambda_func_name" {
  description = "Name to assign to the Lambda Function."
  default     = "Certbot-Cloudflare"
}

variable "lambda_description" {
  type        = string
  default     = "LetsEncrypts Cert Manager for Cloudflare Domains"
  description = "Description to assign to the Lambda Function."
}

variable "lambda_publish_func" {
  default     = false
  description = "Boolean flag that determines if the Lambda function is published as a version."
}

variable "create_sched_event" {
  default     = true
  description = "Boolean flag that determines if a CloudWatch Trigger event is created to renew certificates."
}

variable "lambda_runtime" {
  type        = string
  default     = "python3.7"
  description = "Lambda runtime to use for the function."
}

variable "lambda_timeout" {
  default     = 120
  description = "Number of seconds that the function can run before timing out. The AWS default is 3s and the maximum runtime is 5m"
}

variable "lambda_mem_size" {
  default     = 128
  description = "Amount of RAM (in MB) assigned to the function. The default (and minimum) is 128MB, and the maximum is 3008MB."
}

