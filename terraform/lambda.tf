data "archive_file" "api" {
  type        = "zip"
  source_dir  = "${path.module}/../lambda/api"
  output_path = "${path.module}/.build/api.zip"
}

data "archive_file" "audit" {
  type        = "zip"
  source_dir  = "${path.module}/../lambda/audit"
  output_path = "${path.module}/.build/audit.zip"
}

data "aws_iam_policy_document" "lambda_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

# ---------------------------------------------------------------------------
# API + ingestion Lambda (runs in the VPC to reach RDS)
# ---------------------------------------------------------------------------

resource "aws_security_group" "lambda" {
  name        = "${var.project_name}-lambda-sg"
  description = "Lambda functions that talk to RDS"
  vpc_id      = module.vpc.vpc_id

  tags = { Name = "${var.project_name}-lambda-sg" }
}

resource "aws_vpc_security_group_egress_rule" "lambda_all" {
  security_group_id = aws_security_group.lambda.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
  description       = "Outbound to RDS, Secrets Manager (via NAT)"
}

resource "aws_iam_role" "api_lambda" {
  name               = "${var.project_name}-api-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

resource "aws_iam_role_policy_attachment" "api_lambda_vpc" {
  role       = aws_iam_role.api_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

data "aws_iam_policy_document" "api_lambda_secret" {
  statement {
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [module.rds.db_instance_master_user_secret_arn]
  }
}

resource "aws_iam_role_policy" "api_lambda_secret" {
  name   = "read-db-secret"
  role   = aws_iam_role.api_lambda.id
  policy = data.aws_iam_policy_document.api_lambda_secret.json
}

resource "aws_cloudwatch_log_group" "api" {
  name              = "/aws/lambda/${var.project_name}-api"
  retention_in_days = 1
}

resource "aws_lambda_function" "api" {
  function_name    = "${var.project_name}-api"
  role             = aws_iam_role.api_lambda.arn
  runtime          = "python3.12"
  architectures    = ["arm64"]
  handler          = "handler.lambda_handler"
  filename         = data.archive_file.api.output_path
  source_code_hash = data.archive_file.api.output_base64sha256
  timeout          = 15
  memory_size      = 256

  vpc_config {
    subnet_ids         = module.vpc.private_subnets
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = {
      DB_HOST       = module.rds.db_instance_address
      DB_PORT       = tostring(module.rds.db_instance_port)
      DB_NAME       = var.db_name
      DB_SECRET_ARN = module.rds.db_instance_master_user_secret_arn
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.api_lambda_vpc,
    aws_cloudwatch_log_group.api,
  ]
}

resource "aws_apigatewayv2_api" "main" {
  name          = "${var.project_name}-http-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "api" {
  api_id                 = aws_apigatewayv2_api.main.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.api.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "default" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "$default"
  target    = "integrations/${aws_apigatewayv2_integration.api.id}"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.main.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowHttpApiInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.main.execution_arn}/*/*"
}

# ---------------------------------------------------------------------------
# Audit Lambda (EventBridge -> Lambda -> SNS), outside the VPC
# ---------------------------------------------------------------------------

resource "aws_iam_role" "audit_lambda" {
  name               = "${var.project_name}-audit-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

resource "aws_iam_role_policy_attachment" "audit_lambda_logs" {
  role       = aws_iam_role.audit_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "aws_iam_policy_document" "audit_lambda_sns" {
  statement {
    actions   = ["sns:Publish"]
    resources = [aws_sns_topic.audit.arn]
  }
}

resource "aws_iam_role_policy" "audit_lambda_sns" {
  name   = "publish-audit-topic"
  role   = aws_iam_role.audit_lambda.id
  policy = data.aws_iam_policy_document.audit_lambda_sns.json
}

resource "aws_cloudwatch_log_group" "audit" {
  name              = "/aws/lambda/${var.project_name}-audit"
  retention_in_days = 1
}

resource "aws_lambda_function" "audit" {
  function_name    = "${var.project_name}-audit"
  role             = aws_iam_role.audit_lambda.arn
  runtime          = "python3.12"
  architectures    = ["arm64"]
  handler          = "handler.lambda_handler"
  filename         = data.archive_file.audit.output_path
  source_code_hash = data.archive_file.audit.output_base64sha256
  timeout          = 15
  memory_size      = 128

  environment {
    variables = {
      SNS_TOPIC_ARN = aws_sns_topic.audit.arn
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.audit_lambda_logs,
    aws_cloudwatch_log_group.audit,
  ]
}
