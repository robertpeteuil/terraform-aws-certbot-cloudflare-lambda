# -----------------------------------------------------------------
# AWS LAMBDA CERTBOT FOR CLOUDFLARE DOMAINS
# -----------------------------------------------------------------

provider "aws" {
  region  = var.aws_region
}

# Create random two digit number suffix (used to prevent duplicate names)
resource "random_integer" "id" {
  keepers = {
    # generate new ID when value of domains changes
    domains = var.letsencrypt_domains
  }

  min = 1000
  max = 9999
}

# -----------------------------------------------------------------
# CREATE CLOUDFLARE CREDENTIAL FILE AND UPLOAD TO S3 - if API var set
# -----------------------------------------------------------------

data "template_file" "cloudflare_ini" {
  count = length(var.cloudflare_api_token) > 0 ? 1 : 0

  template = file("${path.module}/templates/cloudflare_ini.tmpl")

  vars = {
    cloudflare_api_token = var.cloudflare_api_token
  }
}

resource "aws_s3_bucket_object" "cloudflare_ini" {
  count = length(var.cloudflare_api_token) > 0 ? 1 : 0

  bucket = var.s3_bucket
  key    = "${var.s3_path}/dns/cloudflare.ini"
  # content                = join("", data.template_file.cloudflare_ini.*.rendered)
  content                = data.template_file.cloudflare_ini[0].rendered
  server_side_encryption = "AES256"
}

# -----------------------------------------------------------------
# CREATE LAMBDA BASE LAYER CONTAINING PYTHON LIBRARIES
# -----------------------------------------------------------------

resource "aws_lambda_layer_version" "certbot_base" {
  filename         = "${path.module}/base_${var.lambda_runtime}.zip"
  source_code_hash = filebase64sha256("${path.module}/base_${var.lambda_runtime}.zip")

  layer_name  = "certbot-cloudflare-base-${replace(var.lambda_runtime, ".", "")}"
  description = "certbot with cloudflare dns plugin"

  compatible_runtimes = [var.lambda_runtime]
}

# -----------------------------------------------------------------
# CREATE LAMBDA FUNCTION USING ZIP FILE 
# -----------------------------------------------------------------

# make zip as script doesnt use a requirements.txt
data "archive_file" "lambda_function" {
  type        = "zip"
  source_file = "${path.module}/function/certbot_cloudflare.py"
  output_path = "${path.module}/lambda.zip"
}

# create lambda using function only zip on top of base layer
resource "aws_lambda_function" "certbot_cloudflare" {
  layers = [aws_lambda_layer_version.certbot_base.arn]

  filename         = "${path.module}/lambda.zip"
  source_code_hash = data.archive_file.lambda_function.output_base64sha256

  function_name = "${var.lambda_func_name}-${random_integer.id.result}"
  description   = "${var.lambda_description}: ${var.letsencrypt_domains}"

  publish     = var.lambda_publish_func ? true : false
  role        = aws_iam_role.lambda_new_funct.arn
  runtime     = var.lambda_runtime
  handler     = "certbot_cloudflare.main"
  timeout     = var.lambda_timeout
  memory_size = var.lambda_mem_size

  tags = var.lambda_tags

  environment {
    variables = {
      letsencrypt_domains = var.letsencrypt_domains
      letsencrypt_email   = var.letsencrypt_email
      s3_bucket           = var.s3_bucket
      s3_path             = var.s3_path
      test_cert           = var.get_test_cert
      sns_topic_arn       = length(var.sns_topic) > 0 ? data.aws_sns_topic.sns_log_topic[0].arn : ""
    }
  }
}

# -----------------------------------------------------------------
# CREATE IAM ROLE AND POLICIES FOR LAMBDA FUNCTION
# -----------------------------------------------------------------

# Create base IAM role
resource "aws_iam_role" "lambda_new_funct" {
  name               = "lambda-${lower(var.lambda_func_name)}-${random_integer.id.result}"
  assume_role_policy = data.aws_iam_policy_document.lambda_new_funct.json
}

# Add policy enabling access to other AWS services
resource "aws_iam_role_policy" "lambda_new_funct_polcy" {
  name   = "lambda-${lower(var.lambda_func_name)}-policy-${random_integer.id.result}"
  role   = aws_iam_role.lambda_new_funct.id
  policy = length(var.sns_topic) > 0 ? data.aws_iam_policy_document.lambda_new_funct_policy_sns[0].json : data.aws_iam_policy_document.lambda_new_funct_policy[0].json
}

# JSON POLICY - assume role
data "aws_iam_policy_document" "lambda_new_funct" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

# JSON POLICY - Logs and S3 only (no SNS)
data "aws_iam_policy_document" "lambda_new_funct_policy" {
  count = length(var.sns_topic) > 0 ? 0 : 1

  statement {
    actions = [
      "iam:PassRole",
      "logs:CreateLogStream",
      "logs:CreateLogGroup",
      "logs:PutLogEvents",
    ]

    resources = ["*"]
  }

  statement {
    actions = [
      "s3:HeadBucket",
      "s3:ListAllMyBuckets",
      "s3:ListBucket",
      "s3:GetObject",
      "s3:PutObject",
      "s3:PutObjectVersionAcl",
    ]

    resources = [
      "arn:aws:s3:::${var.s3_bucket}/${var.s3_path}/dns/cloudflare.ini*",
      "arn:aws:s3:::${var.s3_bucket}/${var.s3_path}/live/*",
    ]
  }
}

# find sns topic arn, if specified (used by JSON policy)
data "aws_sns_topic" "sns_log_topic" {
  count = length(var.sns_topic) > 0 ? 1 : 0
  name  = var.sns_topic
}

# JSON POLICY - Logs, S3 and SNS
data "aws_iam_policy_document" "lambda_new_funct_policy_sns" {
  count = length(var.sns_topic) > 0 ? 1 : 0

  statement {
    actions = [
      "iam:PassRole",
      "logs:CreateLogStream",
      "logs:CreateLogGroup",
      "logs:PutLogEvents",
    ]

    resources = ["*"]
  }

  statement {
    actions = [
      "sns:Publish",
    ]

    resources = [data.aws_sns_topic.sns_log_topic[0].arn]
  }

  statement {
    actions = [
      "s3:HeadBucket",
      "s3:ListAllMyBuckets",
      "s3:ListBucket",
      "s3:GetObject",
      "s3:PutObject",
      "s3:PutObjectVersionAcl",
    ]

    resources = [
      "arn:aws:s3:::${var.s3_bucket}/${var.s3_path}/dns/cloudflare.ini",
      "arn:aws:s3:::${var.s3_bucket}/${var.s3_path}/live/*",
    ]
  }
}

# -----------------------------------------------------------------
# CREATE CLOUDWATCH EVENT TO RENEW CERTS
# -----------------------------------------------------------------

# create cloudwatch event to run every 15 days
resource "aws_cloudwatch_event_rule" "sched" {
  count = var.create_sched_event ? 1 : 0

  name                = "cert_renewal-${random_integer.id.result}"
  description         = "Trigger cert renewal via ${var.lambda_func_name}"
  schedule_expression = "rate(15 days)"
}

# set event target as certbot_cloudflare lambda function 
resource "aws_cloudwatch_event_target" "sched" {
  count = var.create_sched_event ? 1 : 0

  rule      = aws_cloudwatch_event_rule.sched[0].name
  target_id = "Lambda"
  arn       = var.lambda_publish_func ? aws_lambda_function.certbot_cloudflare.qualified_arn : aws_lambda_function.certbot_cloudflare.arn

  input = <<JSON
{
	"Records": [{
		"EventSource": "aws:events"
	}]
}
JSON

}

# -----------------------------------------------------------------
# ENABLE CLOUDWATCH EVENT AS LAMBDA FUNCTION TRIGGER
#   multiple resource blockss until 'null' parameter feature in Terraform v0.12.0
# -----------------------------------------------------------------

# function published - "qualifier" parameter set to function version
# resource "aws_lambda_permission" "sched_published" {
#   count = var.create_sched_event ? var.lambda_publish_func ? 1 : 0 : 0

#   statement_id = "AllowExecutionFromCloudWatch"
#   action = "lambda:InvokeFunction"
#   function_name = aws_lambda_function.certbot_cloudflare.function_name
#   principal = "events.amazonaws.com"
#   source_arn = aws_cloudwatch_event_rule.sched[0].arn
#   qualifier = aws_lambda_function.certbot_cloudflare.version
# }

# # function not published - "qualifier" parameter not be set
# resource "aws_lambda_permission" "sched" {
#   count = var.create_sched_event ? var.lambda_publish_func ? 0 : 1 : 0

#   statement_id = "AllowExecutionFromCloudWatch"
#   action = "lambda:InvokeFunction"
#   function_name = aws_lambda_function.certbot_cloudflare.function_name
#   principal = "events.amazonaws.com"
#   source_arn = aws_cloudwatch_event_rule.sched[0].arn
# }

resource "aws_lambda_permission" "sched_multi" {
  count = var.create_sched_event ? 1 : 0

  statement_id = "AllowExecutionFromCloudWatch"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.certbot_cloudflare.function_name
  principal = "events.amazonaws.com"
  source_arn = aws_cloudwatch_event_rule.sched[0].arn
  qualifier = var.lambda_publish_func ? aws_lambda_function.certbot_cloudflare.version : null
}
