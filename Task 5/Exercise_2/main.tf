# reference: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

#
# pick a region to deploy
#
provider "aws" {
  region          = var.aws_region
}

#
# package the python file in zip format
#
data "archive_file" "lambda_zip" {
    type          = "zip"
    source_file   = "greet_lambda.py"
    output_path   = "lambda_function.zip"
}


#
# decribe how to deploy the Lambda function
#
resource "aws_lambda_function" "greet_lambda" {
  filename         = "lambda_function.zip"
  function_name    = "greet_lambda"
  role             = aws_iam_role.iam_for_lambda.arn
  handler          = "greet_lambda.lambda_handler"
  runtime          = "python3.8"
  kms_key_arn      = aws_kms_key.lambda.arn
  environment {
		variables = {
			greeting = "This is AWS Lambda. Have a good day!"
		}
	}
  #depends_on = [
  #  aws_iam_role_policy_attachment.lambda_logs,
  # aws_cloudwatch_log_group.greet_lambda
  # ]

}


#
# setup an iam role to access Lambda
#
resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}


resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}

# This is to optionally manage the CloudWatch Log Group for the Lambda Function.
# If skipping this resource configuration, 
# also add "logs:CreateLogGroup" to the IAM policy below.

resource "aws_cloudwatch_log_group" "greet_lambda" {
  name              = aws_lambda_function.greet_lambda.function_name
  retention_in_days = 5
}

# See also the following AWS managed policy: AWSLambdaBasicExecutionRole
resource "aws_iam_policy" "lambda_logging" {
  name        = "lambda_logging"
  path        = "/"
  description = "IAM policy for logging from a lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_kms_key" "lambda" {
  description             = "KMS key for Lambda"
  deletion_window_in_days = 10
}
#
#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission
#
# set up permission for Lambda to access Cloudwatch
#

resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.greet_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.one_minute.arn
}

resource "aws_cloudwatch_event_rule" "one_minute" {
  name = "one_minute_Lambda_event"
  depends_on = [
    "aws_lambda_function.greet_lambda"
  ]
  schedule_expression = "rate(1 minute)"
}

resource "aws_cloudwatch_event_target" "greet_lambda" {
  target_id = "greet_lambda" 
  rule = aws_cloudwatch_event_rule.one_minute.name
  arn = aws_lambda_function.greet_lambda.arn
}

