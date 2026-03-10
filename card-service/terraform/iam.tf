# Rol base - Le dice a AWS "este rol es para una Lambda"
resource "aws_iam_role" "card_lambda_role" {
  name = "card-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# Permisos concretos que tiene ese rol
resource "aws_iam_role_policy" "card_lambda_policy" {
  name = "card-lambda-policy"
  role = aws_iam_role.card_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Permiso para leer y eliminar mensajes de SQS
      # Permiso para leer y eliminar mensajes de SQS
     {
        Effect = "Allow"
        Action = [
            "sqs:ReceiveMessage",
            "sqs:DeleteMessage",
            "sqs:GetQueueAttributes",
            "sqs:SendMessage"
        ]
        Resource = "*"  # ← cambiamos el ARN específico por * para cubrir ambas colas
     },
      # Permiso para leer y escribir en DynamoDB
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:UpdateItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = "*"
      },
      # Permiso para escribir logs (para ver qué pasa cuando se ejecuta)
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}