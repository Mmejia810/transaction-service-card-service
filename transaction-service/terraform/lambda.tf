# ============================================
# EMPAQUETAR EL CÓDIGO PYTHON EN ZIPS
# ============================================

data "archive_file" "purchase_zip" {
  type        = "zip"
  source_dir  = "../src/transaction_purchase"
  output_path = "../src/zips/transaction_purchase.zip"
}

data "archive_file" "save_zip" {
  type        = "zip"
  source_dir  = "../src/transaction_save"
  output_path = "../src/zips/transaction_save.zip"
}

data "archive_file" "paid_zip" {
  type        = "zip"
  source_dir  = "../src/transaction_paid"
  output_path = "../src/zips/transaction_paid.zip"
}

data "archive_file" "report_zip" {
  type        = "zip"
  source_dir  = "../src/card_get_report"
  output_path = "../src/zips/card_get_report.zip"
}

# ============================================
# CREAR LAS LAMBDAS EN AWS
# ============================================

resource "aws_lambda_function" "transaction_purchase" {
  filename         = data.archive_file.purchase_zip.output_path
  function_name    = "card-purchase-lambda"
  role             = aws_iam_role.transaction_lambda_role.arn
  handler          = "handler.lambda_handler"
  runtime          = "python3.11"
  timeout          = 15
  source_code_hash = data.archive_file.purchase_zip.output_base64sha256

  environment {
    variables = {
      CARD_TABLE        = "card-table"
      TRANSACTION_TABLE = "transaction-table"
    }
  }
}

resource "aws_lambda_function" "transaction_save" {
  filename         = data.archive_file.save_zip.output_path
  function_name    = "card-transaction-save-lambda"
  role             = aws_iam_role.transaction_lambda_role.arn
  handler          = "handler.lambda_handler"
  runtime          = "python3.11"
  timeout          = 15
  source_code_hash = data.archive_file.save_zip.output_base64sha256

  environment {
    variables = {
      CARD_TABLE        = "card-table"
      TRANSACTION_TABLE = "transaction-table"
    }
  }
}

resource "aws_lambda_function" "transaction_paid" {
  filename         = data.archive_file.paid_zip.output_path
  function_name    = "card-paid-credit-card-lambda"
  role             = aws_iam_role.transaction_lambda_role.arn
  handler          = "handler.lambda_handler"
  runtime          = "python3.11"
  timeout          = 15
  source_code_hash = data.archive_file.paid_zip.output_base64sha256

  environment {
    variables = {
      CARD_TABLE        = "card-table"
      TRANSACTION_TABLE = "transaction-table"
    }
  }
}

resource "aws_lambda_function" "card_get_report" {
  filename         = data.archive_file.report_zip.output_path
  function_name    = "card-get-report-lambda"
  role             = aws_iam_role.transaction_lambda_role.arn
  handler          = "handler.lambda_handler"
  runtime          = "python3.11"
  timeout          = 30
  source_code_hash = data.archive_file.report_zip.output_base64sha256

  environment {
    variables = {
      REPORTS_BUCKET    = aws_s3_bucket.reports_bucket.bucket
      CARD_TABLE        = "card-table"
      TRANSACTION_TABLE = "transaction-table"
    }
  }
}