import json
import uuid
import random
import boto3
from datetime import datetime, timezone

dynamodb = boto3.resource('dynamodb')
card_table = dynamodb.Table('card-table')

def lambda_handler(event, context):
    """
    Recibe mensajes de SQS con este formato:
    {
        "userId": "uuid-del-usuario",
        "request": "DEBIT" o "CREDIT"
    }
    """
    
    for record in event['Records']:
        try:
            # 1. Leer el mensaje que llegó de SQS
            body = json.loads(record['body'])
            user_id = body['userId']
            card_type = body['request']  # DEBIT o CREDIT
            
            print(f"Creando tarjeta {card_type} para usuario {user_id}")
            
            # 2. Generar score aleatorio entre 0 y 100
            score = random.randint(0, 100)
            
            # 3. Calcular el monto con la fórmula del proyecto
            # monto = 100 + (score / 100) * 9,999,900
            amount = 100 + (score / 100) * 9_999_900
            amount = round(amount, 2)
            
            # 4. Definir estado y balance según el tipo de tarjeta
            if card_type == "DEBIT":
                status = "ACTIVATED"
                balance = 0        # débito empieza en 0
            elif card_type == "CREDIT":
                status = "PENDING"
                balance = amount   # crédito tiene el cupo aprobado
            else:
                raise ValueError(f"Tipo de tarjeta inválido: {card_type}")
            
            # 5. Guardar en DynamoDB
            card_id = str(uuid.uuid4())
            created_at = datetime.now(timezone.utc).isoformat()
            
            card_item = {
                "uuid":      card_id,
                "user_id":   user_id,
                "type":      card_type,
                "status":    status,
                "balance":   str(balance),  # DynamoDB no acepta float, usamos string
                "score":     score,
                "createdAt": created_at
            }
            
            card_table.put_item(Item=card_item)
            
            print(f"✅ Tarjeta creada: {card_id} | {card_type} | {status} | balance: {balance}")

        except Exception as e:
            print(f"❌ Error: {str(e)}")
            raise e  # Relanza el error para que SQS reintente y eventualmente vaya a DLQ

    return {"statusCode": 200, "body": "Tarjetas procesadas"}