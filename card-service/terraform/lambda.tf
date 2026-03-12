# ============================================
# EMPAQUETAR EL CÓDIGO PYTHON EN ZIPS
# ============================================

data "archive_file" "approval_worker_zip" {
  type        = "zip"
  source_dir  = "../src/card_approval_worker"
  output_path = "../src/zips/card_approval_worker.zip"
}

data "archive_file" "activate_zip" {
  type        = "zip"
  source_dir  = "../src/card_activate"
  output_path = "../src/zips/card_activate.zip"
}

data "archive_file" "failed_zip" {
  type        = "zip"
  source_dir  = "../src/card_request_failed"
  output_path = "../src/zips/card_request_failed.zip"
}

# ============================================
# CREAR LAS LAMBDAS EN AWS
# ============================================

# Lambda principal - escucha SQS y crea tarjetas
resource "aws_lambda_function" "card_approval_worker" {
  filename         = data.archive_file.approval_worker_zip.output_path
  function_name    = "card-approval-worker"
  role             = aws_iam_role.card_lambda_role.arn
  handler          = "handler.lambda_handler"  # archivo.funcion
  runtime          = "python3.11"
  timeout          = 30
  source_code_hash = data.archive_file.approval_worker_zip.output_base64sha256

    environment {
    variables = {
      NOTIFICATION_QUEUE_URL = "https://sqs.us-east-1.amazonaws.com/825982958931/notification-email-sqs"
    }
  }
}

# Lambda para activar tarjeta de crédito
resource "aws_lambda_function" "card_activate" {
  filename         = data.archive_file.activate_zip.output_path
  function_name    = "card-activate-lambda"
  role             = aws_iam_role.card_lambda_role.arn
  handler          = "handler.lambda_handler"
  runtime          = "python3.11"
  timeout          = 15
  source_code_hash = data.archive_file.activate_zip.output_base64sha256

    environment {
    variables = {
      NOTIFICATION_QUEUE_URL = "https://sqs.us-east-1.amazonaws.com/825982958931/notification-email-sqs"
    }
  }
}

# Lambda para manejar errores de la DLQ
resource "aws_lambda_function" "card_request_failed" {
  filename         = data.archive_file.failed_zip.output_path
  function_name    = "card-request-failed"
  role             = aws_iam_role.card_lambda_role.arn
  handler          = "handler.lambda_handler"
  runtime          = "python3.11"
  timeout          = 15
  source_code_hash = data.archive_file.failed_zip.output_base64sha256
}

# ============================================
# CONECTAR LAS COLAS SQS CON LAS LAMBDAS
# ============================================

# Cola principal → card_approval_worker
resource "aws_lambda_event_source_mapping" "sqs_to_approval" {
  event_source_arn = aws_sqs_queue.card_queue.arn
  function_name    = aws_lambda_function.card_approval_worker.arn
  batch_size       = 5
  enabled          = true
}

# DLQ → card_request_failed
resource "aws_lambda_event_source_mapping" "dlq_to_failed" {
  event_source_arn = aws_sqs_queue.card_dlq.arn
  function_name    = aws_lambda_function.card_request_failed.arn
  batch_size       = 5
  enabled          = true
}