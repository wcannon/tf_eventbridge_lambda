terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "us-west-2"
}

resource "aws_iam_role" "scheduler_role" {
  name = "scheduler_role"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Resource": "arn:aws:lambda:us-east-1:012800249358:function:example-lambda",
          "Principal": {
            "Service": "events.amazonaws.com"
          }
          "Effect" : "Allow",
          "Action" : [
            "lambda:InvokeFunction"
          ],
        }
      ]
    }
  )

  tags = {
    tag-key = "tag-value"
  }
}


resource "aws_scheduler_schedule" "example" {
  name       = "my-lambda-schedule"
  group_name = "default"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression = "rate(1 hour)"

  target {
    arn      = "arn:aws:lambda:us-east-1:012800249358:function:example-lambda"
    role_arn = aws_iam_role.scheduler_role.arn
  }
}
