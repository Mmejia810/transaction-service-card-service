# ============================================
# CREAR EL API
# ============================================

resource "aws_api_gateway_rest_api" "transaction_api" {
  name        = "transaction-service-api"
  description = "API para el servicio de transacciones"
}

# ============================================
# RUTA: /transactions
# ============================================

resource "aws_api_gateway_resource" "transactions" {
  rest_api_id = aws_api_gateway_rest_api.transaction_api.id
  parent_id   = aws_api_gateway_rest_api.transaction_api.root_resource_id
  path_part   = "transactions"
}

# ============================================
# RUTA: /transactions/purchase
# ============================================

resource "aws_api_gateway_resource" "transactions_purchase" {
  rest_api_id = aws_api_gateway_rest_api.transaction_api.id
  parent_id   = aws_api_gateway_resource.transactions.id
  path_part   = "purchase"
}

resource "aws_api_gateway_method" "post_purchase" {
  rest_api_id   = aws_api_gateway_rest_api.transaction_api.id
  resource_id   = aws_api_gateway_resource.transactions_purchase.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "purchase_integration" {
  rest_api_id             = aws_api_gateway_rest_api.transaction_api.id
  resource_id             = aws_api_gateway_resource.transactions_purchase.id
  http_method             = aws_api_gateway_method.post_purchase.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.transaction_purchase.invoke_arn
}

resource "aws_lambda_permission" "allow_apigw_purchase" {
  statement_id  = "AllowAPIGatewayPurchase"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.transaction_purchase.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.transaction_api.execution_arn}/*/*"
}

# ============================================
# RUTA: /transactions/save/{card_id}
# ============================================

resource "aws_api_gateway_resource" "transactions_save" {
  rest_api_id = aws_api_gateway_rest_api.transaction_api.id
  parent_id   = aws_api_gateway_resource.transactions.id
  path_part   = "save"
}

resource "aws_api_gateway_resource" "transactions_save_card_id" {
  rest_api_id = aws_api_gateway_rest_api.transaction_api.id
  parent_id   = aws_api_gateway_resource.transactions_save.id
  path_part   = "{card_id}"
}

resource "aws_api_gateway_method" "post_save" {
  rest_api_id   = aws_api_gateway_rest_api.transaction_api.id
  resource_id   = aws_api_gateway_resource.transactions_save_card_id.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "save_integration" {
  rest_api_id             = aws_api_gateway_rest_api.transaction_api.id
  resource_id             = aws_api_gateway_resource.transactions_save_card_id.id
  http_method             = aws_api_gateway_method.post_save.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.transaction_save.invoke_arn
}

resource "aws_lambda_permission" "allow_apigw_save" {
  statement_id  = "AllowAPIGatewaySave"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.transaction_save.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.transaction_api.execution_arn}/*/*"
}

# ============================================
# RUTA: /card
# ============================================

resource "aws_api_gateway_resource" "card" {
  rest_api_id = aws_api_gateway_rest_api.transaction_api.id
  parent_id   = aws_api_gateway_rest_api.transaction_api.root_resource_id
  path_part   = "card"
}

# ============================================
# RUTA: /card/paid/{card_id}
# ============================================

resource "aws_api_gateway_resource" "card_paid" {
  rest_api_id = aws_api_gateway_rest_api.transaction_api.id
  parent_id   = aws_api_gateway_resource.card.id
  path_part   = "paid"
}

resource "aws_api_gateway_resource" "card_paid_card_id" {
  rest_api_id = aws_api_gateway_rest_api.transaction_api.id
  parent_id   = aws_api_gateway_resource.card_paid.id
  path_part   = "{card_id}"
}

resource "aws_api_gateway_method" "post_paid" {
  rest_api_id   = aws_api_gateway_rest_api.transaction_api.id
  resource_id   = aws_api_gateway_resource.card_paid_card_id.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "paid_integration" {
  rest_api_id             = aws_api_gateway_rest_api.transaction_api.id
  resource_id             = aws_api_gateway_resource.card_paid_card_id.id
  http_method             = aws_api_gateway_method.post_paid.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.transaction_paid.invoke_arn
}

resource "aws_lambda_permission" "allow_apigw_paid" {
  statement_id  = "AllowAPIGatewayPaid"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.transaction_paid.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.transaction_api.execution_arn}/*/*"
}

# ============================================
# RUTA: /report/{card_id}
# ============================================

resource "aws_api_gateway_resource" "report" {
  rest_api_id = aws_api_gateway_rest_api.transaction_api.id
  parent_id   = aws_api_gateway_rest_api.transaction_api.root_resource_id
  path_part   = "report"
}

resource "aws_api_gateway_resource" "card_report_id" {
  rest_api_id = aws_api_gateway_rest_api.transaction_api.id
  parent_id   = aws_api_gateway_resource.report.id
  path_part   = "{card_id}"
}

resource "aws_api_gateway_method" "get_report" {
  rest_api_id   = aws_api_gateway_rest_api.transaction_api.id
  resource_id   = aws_api_gateway_resource.card_report_id.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "report_integration" {
  rest_api_id             = aws_api_gateway_rest_api.transaction_api.id
  resource_id             = aws_api_gateway_resource.card_report_id.id
  http_method             = aws_api_gateway_method.get_report.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.card_get_report.invoke_arn
}

resource "aws_lambda_permission" "allow_apigw_report" {
  statement_id  = "AllowAPIGatewayReport"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.card_get_report.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.transaction_api.execution_arn}/*/*"
}

# ============================================
# DESPLEGAR EL API
# ============================================

resource "aws_api_gateway_deployment" "transaction_deploy" {
  depends_on = [
    aws_api_gateway_integration.purchase_integration,
    aws_api_gateway_integration.save_integration,
    aws_api_gateway_integration.paid_integration,
    aws_api_gateway_integration.report_integration,
    aws_api_gateway_integration_response.options_purchase,
    aws_api_gateway_integration_response.options_save,
    aws_api_gateway_integration_response.options_paid,
    aws_api_gateway_integration_response.options_report,
  ]

  rest_api_id = aws_api_gateway_rest_api.transaction_api.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.card_report_id.id,
      aws_api_gateway_method.get_report.id,
      aws_api_gateway_integration.report_integration.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "transaction_stage" {
  deployment_id = aws_api_gateway_deployment.transaction_deploy.id
  rest_api_id   = aws_api_gateway_rest_api.transaction_api.id
  stage_name    = "dev"
}

# ============================================
# OUTPUTS
# ============================================

output "purchase_url" {
  value = "${aws_api_gateway_stage.transaction_stage.invoke_url}/transactions/purchase"
}

output "save_url" {
  value = "${aws_api_gateway_stage.transaction_stage.invoke_url}/transactions/save/{card_id}"
}

output "paid_url" {
  value = "${aws_api_gateway_stage.transaction_stage.invoke_url}/card/paid/{card_id}"
}

output "report_url" {
  value = "${aws_api_gateway_stage.transaction_stage.invoke_url}/report/{card_id}"
}

# ── CORS: /transactions/purchase ──
resource "aws_api_gateway_method" "options_purchase" {
  rest_api_id   = aws_api_gateway_rest_api.transaction_api.id
  resource_id   = aws_api_gateway_resource.transactions_purchase.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "options_purchase" {
  rest_api_id = aws_api_gateway_rest_api.transaction_api.id
  resource_id = aws_api_gateway_resource.transactions_purchase.id
  http_method = aws_api_gateway_method.options_purchase.http_method
  type        = "MOCK"
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "options_purchase" {
  rest_api_id = aws_api_gateway_rest_api.transaction_api.id
  resource_id = aws_api_gateway_resource.transactions_purchase.id
  http_method = aws_api_gateway_method.options_purchase.http_method
  status_code = "200"
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "options_purchase" {
  rest_api_id = aws_api_gateway_rest_api.transaction_api.id
  resource_id = aws_api_gateway_resource.transactions_purchase.id
  http_method = aws_api_gateway_method.options_purchase.http_method
  status_code = "200"
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,Authorization'"
    "method.response.header.Access-Control-Allow-Methods" = "'OPTIONS,POST'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
  depends_on = [aws_api_gateway_integration.options_purchase]
}

# ── CORS: /transactions/save/{card_id} ──
resource "aws_api_gateway_method" "options_save" {
  rest_api_id   = aws_api_gateway_rest_api.transaction_api.id
  resource_id   = aws_api_gateway_resource.transactions_save_card_id.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "options_save" {
  rest_api_id = aws_api_gateway_rest_api.transaction_api.id
  resource_id = aws_api_gateway_resource.transactions_save_card_id.id
  http_method = aws_api_gateway_method.options_save.http_method
  type        = "MOCK"
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "options_save" {
  rest_api_id = aws_api_gateway_rest_api.transaction_api.id
  resource_id = aws_api_gateway_resource.transactions_save_card_id.id
  http_method = aws_api_gateway_method.options_save.http_method
  status_code = "200"
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "options_save" {
  rest_api_id = aws_api_gateway_rest_api.transaction_api.id
  resource_id = aws_api_gateway_resource.transactions_save_card_id.id
  http_method = aws_api_gateway_method.options_save.http_method
  status_code = "200"
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,Authorization'"
    "method.response.header.Access-Control-Allow-Methods" = "'OPTIONS,POST'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
  depends_on = [aws_api_gateway_integration.options_save]
}

# ── CORS: /card/paid/{card_id} ──
resource "aws_api_gateway_method" "options_paid" {
  rest_api_id   = aws_api_gateway_rest_api.transaction_api.id
  resource_id   = aws_api_gateway_resource.card_paid_card_id.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "options_paid" {
  rest_api_id = aws_api_gateway_rest_api.transaction_api.id
  resource_id = aws_api_gateway_resource.card_paid_card_id.id
  http_method = aws_api_gateway_method.options_paid.http_method
  type        = "MOCK"
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "options_paid" {
  rest_api_id = aws_api_gateway_rest_api.transaction_api.id
  resource_id = aws_api_gateway_resource.card_paid_card_id.id
  http_method = aws_api_gateway_method.options_paid.http_method
  status_code = "200"
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "options_paid" {
  rest_api_id = aws_api_gateway_rest_api.transaction_api.id
  resource_id = aws_api_gateway_resource.card_paid_card_id.id
  http_method = aws_api_gateway_method.options_paid.http_method
  status_code = "200"
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,Authorization'"
    "method.response.header.Access-Control-Allow-Methods" = "'OPTIONS,POST'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
  depends_on = [aws_api_gateway_integration.options_paid]
}

# ── CORS: /report/{card_id} ──
resource "aws_api_gateway_method" "options_report" {
  rest_api_id   = aws_api_gateway_rest_api.transaction_api.id
  resource_id   = aws_api_gateway_resource.card_report_id.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "options_report" {
  rest_api_id = aws_api_gateway_rest_api.transaction_api.id
  resource_id = aws_api_gateway_resource.card_report_id.id
  http_method = aws_api_gateway_method.options_report.http_method
  type        = "MOCK"
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "options_report" {
  rest_api_id = aws_api_gateway_rest_api.transaction_api.id
  resource_id = aws_api_gateway_resource.card_report_id.id
  http_method = aws_api_gateway_method.options_report.http_method
  status_code = "200"
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "options_report" {
  rest_api_id = aws_api_gateway_rest_api.transaction_api.id
  resource_id = aws_api_gateway_resource.card_report_id.id
  http_method = aws_api_gateway_method.options_report.http_method
  status_code = "200"
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,Authorization'"
    "method.response.header.Access-Control-Allow-Methods" = "'OPTIONS,POST'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
  depends_on = [aws_api_gateway_integration.options_report]
}