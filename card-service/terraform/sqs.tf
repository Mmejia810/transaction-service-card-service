# DLQ - Cola de errores (atrapa mensajes que fallaron)
resource "aws_sqs_queue" "card_dlq" {
  name                      = "error-create-request-card-sqs"
  message_retention_seconds = 1209600  # guarda mensajes fallidos por 14 días
}

# Cola principal donde llegan las solicitudes de tarjetas
resource "aws_sqs_queue" "card_queue" {
  name                       = "create-request-card-sqs"
  visibility_timeout_seconds = 30

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.card_dlq.arn
    maxReceiveCount     = 3  # si falla 3 veces, el mensaje va a la DLQ
  })
}