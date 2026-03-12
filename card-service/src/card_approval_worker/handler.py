import json
import uuid
import random
import boto3
import os
from datetime import datetime, timezone

dynamodb = boto3.resource('dynamodb')
sqs = boto3.client('sqs', region_name='us-east-1')
card_table = dynamodb.Table('card-table')

def lambda_handler(event, context):
    for record in event['Records']:
        try:
            # 1. Leer el mensaje que llegó de SQS
            body      = json.loads(record['body'])
            user_id   = body['userId']
            card_type = body['request']  # DEBIT o CREDIT

            print(f"Creando tarjeta {card_type} para usuario {user_id}")

            # 2. Generar score aleatorio entre 0 y 100
            score = random.randint(0, 100)

            # 3. Calcular el monto con la fórmula del proyecto
            amount = 100 + (score / 100) * 9_999_900
            amount = round(amount, 2)

            # 4. Definir estado y balance según el tipo de tarjeta
            if card_type == "DEBIT":
                status  = "ACTIVATED"
                balance = 0
            elif card_type == "CREDIT":
                status  = "PENDING"
                balance = amount
            else:
                raise ValueError(f"Tipo de tarjeta inválido: {card_type}")

            # 5. Guardar en DynamoDB
            card_id    = str(uuid.uuid4())
            created_at = datetime.now(timezone.utc).isoformat()

            card_table.put_item(Item={
                "uuid":      card_id,
                "user_id":   user_id,
                "type":      card_type,
                "status":    status,
                "balance":   str(balance),
                "score":     score,
                "createdAt": created_at
            })

            print(f"✅ Tarjeta creada: {card_id} | {card_type} | {status} | balance: {balance}")

            # 6. Enviar notificación CARD.CREATE
            try:
                sqs.send_message(
                    QueueUrl=os.environ.get('NOTIFICATION_QUEUE_URL'),
                    MessageBody=json.dumps({
                        "type": "CARD.CREATE",
                        "data": {
                            "date":   created_at,
                            "type":   card_type,
                            "amount": str(balance)
                        }
                    })
                )
            except Exception as notif_error:
                print(f"[ERROR] Notificación CARD.CREATE falló: {notif_error}")

        except Exception as e:
            print(f"❌ Error: {str(e)}")
            raise e

    return {"statusCode": 200, "body": "Tarjetas procesadas"}