terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}


provider "aws" {
  region          = "${var.aws_region}"
}

data "archive_file" "lambda_zip" {
    type          = "zip"
    source_file   = "greet_lambda.py"
    output_path   = "lambda_function.zip"
}
#
# setup an iam role to access Lambda
#
resource "aws_iam_role" "for_lambda" {
  name = "iam_role_for_lambda"

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


resource "aws_lambda_function" "greet_lambda" {
  filename         = "lambda_function.zip"
  function_name    = "greet_lambda"
  role             = "${aws_iam_role.for_lambda.arn}"
  handler          = "greet_lambda.lambda_handler"
  runtime          = "python3.8"
}