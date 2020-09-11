# reference: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}


provider "aws" {
  region          = var.aws_region
}

data "archive_file" "lambda_zip" {
    type          = "zip"
    source_file   = "greet_lambda.py"
    output_path   = "lambda_function.zip"
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
  retention_in_days = 14
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

resource "aws_lambda_function" "greet_lambda" {
  filename         = "lambda_function.zip"
  function_name    = "greet_lambda"
  role             = aws_iam_role.iam_for_lambda.arn
  handler          = "greet_lambda.lambda_handler"
  runtime          = "python3.8"
  environment {
		variables = {
			greeting = "Greeting AWS Lambda. Have a good day"
		}
	}
  #depends_on = [
  #  aws_iam_role_policy_attachment.lambda_logs,
  # aws_cloudwatch_log_group.greet_lambda
  # ]

}

