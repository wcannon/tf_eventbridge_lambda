data "archive_file" "lambda_zip" {
  type             = "zip"
  source_file      = "schedule_test.py"
  output_file_mode = "0666"
  output_path      = "schedule_test.py.zip"
}

resource "aws_lambda_function" "processing_lambda" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "testwww"
  handler          = "schedule_test.lambda_handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  role             = aws_iam_role.processing_lambda_role.arn

  runtime = "python3.9"
  timeout = 900
  #memory_size = 10240
  #tags        = var.config.tags
}

resource "aws_iam_role" "processing_lambda_role" {
  name = "test-www-role"
  path = "/service-role/"
  #permissions_boundary = local.config.permission_boundary_arn
  assume_role_policy = data.aws_iam_policy_document.assume-role-policy_document.json

  inline_policy {
    name   = "test_policy"
    policy = data.aws_iam_policy_document.test_policy_document.json
  }
}

data "aws_iam_policy_document" "assume-role-policy_document" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}


data "aws_iam_policy_document" "test_policy_document" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:AssociateKmsKey"
    ]
    resources = ["*"]

  }
}

resource "aws_cloudwatch_event_rule" "schedule" {
  name        = "test-www"
  description = "Schedule for Lambda Function"
  #schedule_expression = rate(1 minutes)
  #schedule_expression = "cron(0/10 * ? * MON-FRI *)"
  schedule_expression = var.lambda_cron
}

resource "aws_cloudwatch_event_target" "schedule_lambda" {
  rule      = aws_cloudwatch_event_rule.schedule.name
  target_id = "processing_lambda"
  arn       = aws_lambda_function.processing_lambda.arn
}


resource "aws_lambda_permission" "allow_events_bridge_to_run_lambda" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.processing_lambda.function_name
  principal     = "events.amazonaws.com"
}

variable "lambda_cron" {
  description = "cron expression"
  #default     = "cron(0/10 * ? * MON-FRI *)"
  default = "cron(0 */4 ? * 1-7 *)"
}