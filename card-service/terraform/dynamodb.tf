#tabla principal de tarjetas

resource "aws_dynamodb_table" "card_table" {
    name = "card-table"
    billing_mode = "PAY_PER_REQUEST"
    hash_key = "uuid"
    range_key = "createdAt"

    attribute {
      name = "uuid"
      type = "S"
    }

    attribute {
      name = "createdAt"
      type = "S"
    }

    tags = {
        Name = "card-table"
    }

}


# Tabla para guardar los errores
resource "aws_dynamodb_table" "card_table_error" {
  name         = "card-table-error"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "uuid"
  range_key    = "createdAt"

  attribute {
    name = "uuid"
    type = "S"
  }

  attribute {
    name = "createdAt"
    type = "S"
  }

  tags = {
    Name = "card-table-error"
  }
}