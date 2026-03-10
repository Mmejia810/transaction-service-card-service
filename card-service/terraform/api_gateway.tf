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
  # Espera a que todas las integraciones estén listas
  depends_on = [
    aws_api_gateway_integration.card_activate_integration,
  ]

  rest_api_id = aws_api_gateway_rest_api.card_api.id
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