# ============================================
# CREAR EL API
# ============================================

resource "aws_api_gateway_rest_api" "card_api" {
  name        = "card-service-api"
  description = "API para el servicio de tarjetas"
}

# ============================================
# RUTA: /card
# ============================================

resource "aws_api_gateway_resource" "card" {
  rest_api_id = aws_api_gateway_rest_api.card_api.id
  parent_id   = aws_api_gateway_rest_api.card_api.root_resource_id
  path_part   = "card"
}

# ============================================
# RUTA: /card/activate
# ============================================

resource "aws_api_gateway_resource" "card_activate" {
  rest_api_id = aws_api_gateway_rest_api.card_api.id
  parent_id   = aws_api_gateway_resource.card.id
  path_part   = "activate"
}

# Método POST para /card/activate
resource "aws_api_gateway_method" "post_card_activate" {
  rest_api_id   = aws_api_gateway_rest_api.card_api.id
  resource_id   = aws_api_gateway_resource.card_activate.id
  http_method   = "POST"
  authorization = "NONE"
}

# Conectar POST /card/activate → Lambda card_activate
resource "aws_api_gateway_integration" "card_activate_integration" {
  rest_api_id             = aws_api_gateway_rest_api.card_api.id
  resource_id             = aws_api_gateway_resource.card_activate.id
  http_method             = aws_api_gateway_method.post_card_activate.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.card_activate.invoke_arn
}

# Permiso para que API Gateway ejecute la Lambda
resource "aws_lambda_permission" "allow_apigw_activate" {
  statement_id  = "AllowAPIGatewayActivate"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.card_activate.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.card_api.execution_arn}/*/*"
}

# ============================================
# DESPLEGAR EL API
# ============================================

resource "aws_api_gateway_deployment" "card_deploy" {
  depends_on = [
    aws_api_gateway_integration.card_activate_integration,
    aws_api_gateway_integration.get_cards_integration,
    aws_api_gateway_integration_response.options_activate,
    aws_api_gateway_integration_response.options_card_user,
  ]
  rest_api_id = aws_api_gateway_rest_api.card_api.id
  lifecycle {
    create_before_destroy = true
  }
}
resource "aws_api_gateway_stage" "card_stage" {
  deployment_id = aws_api_gateway_deployment.card_deploy.id
  rest_api_id   = aws_api_gateway_rest_api.card_api.id
  stage_name    = "dev"
}

# ============================================
# OUTPUTS - URLs que necesitarás para probar
# ============================================

output "api_url" {
  value       = "${aws_api_gateway_stage.card_stage.invoke_url}"
  description = "URL base del API"
}

output "activate_card_url" {
  value       = "${aws_api_gateway_stage.card_stage.invoke_url}/card/activate"
  description = "URL para activar tarjeta"
}

output "card_queue_url" {
  value       = aws_sqs_queue.card_queue.url
  description = "URL de la cola SQS"
}


# ============================================
# RUTA: /card/{user_id}
# ============================================

resource "aws_api_gateway_resource" "card_user" {
  rest_api_id = aws_api_gateway_rest_api.card_api.id
  parent_id   = aws_api_gateway_resource.card.id
  path_part   = "{user_id}"
}

resource "aws_api_gateway_method" "get_cards" {
  rest_api_id   = aws_api_gateway_rest_api.card_api.id
  resource_id   = aws_api_gateway_resource.card_user.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "get_cards_integration" {
  rest_api_id             = aws_api_gateway_rest_api.card_api.id
  resource_id             = aws_api_gateway_resource.card_user.id
  http_method             = aws_api_gateway_method.get_cards.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.card_get_cards.invoke_arn
}

resource "aws_lambda_permission" "allow_apigw_get_cards" {
  statement_id  = "AllowAPIGatewayGetCards"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.card_get_cards.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.card_api.execution_arn}/*/*"
}

# ── CORS: /card/activate ──
resource "aws_api_gateway_method" "options_activate" {
  rest_api_id   = aws_api_gateway_rest_api.card_api.id
  resource_id   = aws_api_gateway_resource.card_activate.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "options_activate" {
  rest_api_id = aws_api_gateway_rest_api.card_api.id
  resource_id = aws_api_gateway_resource.card_activate.id
  http_method = aws_api_gateway_method.options_activate.http_method
  type        = "MOCK"
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "options_activate" {
  rest_api_id = aws_api_gateway_rest_api.card_api.id
  resource_id = aws_api_gateway_resource.card_activate.id
  http_method = aws_api_gateway_method.options_activate.http_method
  status_code = "200"
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "options_activate" {
  rest_api_id = aws_api_gateway_rest_api.card_api.id
  resource_id = aws_api_gateway_resource.card_activate.id
  http_method = aws_api_gateway_method.options_activate.http_method
  status_code = "200"
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,Authorization'"
    "method.response.header.Access-Control-Allow-Methods" = "'OPTIONS,POST'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
  depends_on = [aws_api_gateway_integration.options_activate]
}

# ── CORS: /card/{user_id} ──
resource "aws_api_gateway_method" "options_card_user" {
  rest_api_id   = aws_api_gateway_rest_api.card_api.id
  resource_id   = aws_api_gateway_resource.card_user.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "options_card_user" {
  rest_api_id = aws_api_gateway_rest_api.card_api.id
  resource_id = aws_api_gateway_resource.card_user.id
  http_method = aws_api_gateway_method.options_card_user.http_method
  type        = "MOCK"
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "options_card_user" {
  rest_api_id = aws_api_gateway_rest_api.card_api.id
  resource_id = aws_api_gateway_resource.card_user.id
  http_method = aws_api_gateway_method.options_card_user.http_method
  status_code = "200"
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "options_card_user" {
  rest_api_id = aws_api_gateway_rest_api.card_api.id
  resource_id = aws_api_gateway_resource.card_user.id
  http_method = aws_api_gateway_method.options_card_user.http_method
  status_code = "200"
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,Authorization'"
    "method.response.header.Access-Control-Allow-Methods" = "'OPTIONS,GET'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
  depends_on = [aws_api_gateway_integration.options_card_user]
}