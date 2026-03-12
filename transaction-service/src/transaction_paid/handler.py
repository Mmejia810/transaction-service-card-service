import json
import uuid
import boto3
import os
from datetime import datetime, timezone
from boto3.dynamodb.conditions import Attr
from decimal import Decimal

dynamodb = boto3.resource('dynamodb')
sqs = boto3.client('sqs', region_name='us-east-1')
card_table        = dynamodb.Table(os.environ['CARD_TABLE'])
transaction_table = dynamodb.Table(os.environ['TRANSACTION_TABLE'])

def lambda_handler(event, context):
    try:
        card_id  = event['pathParameters']['card_id']
        body     = json.loads(event['body'])
        amount   = Decimal(str(body['amount']))
        merchant = body.get('merchant', 'PSE')

        # 1. Buscar la tarjeta
        response = card_table.scan(
            FilterExpression=Attr('uuid').eq(card_id)
        )
        cards = response.get('Items', [])

        if not cards:
            return {
                "statusCode": 404,
                "body": json.dumps({"message": "Tarjeta no encontrada"})
            }

        card      = cards[0]
        card_type = card['type']

        # 2. Solo crédito
        if card_type != "CREDIT":
            return {
                "statusCode": 400,
                "body": json.dumps({"message": "Solo se puede pagar tarjetas de crédito"})
            }

        # 3. Calcular deuda actual
        used_response = transaction_table.scan(
            FilterExpression=Attr('cardId').eq(card_id) & Attr('type').eq('PURCHASE')
        )
        paid_response = transaction_table.scan(
            FilterExpression=Attr('cardId').eq(card_id) & Attr('type').eq('PAYMENT_BALANCE')
        )

        total_purchases = sum(Decimal(str(t['amount'])) for t in used_response.get('Items', []))
        total_paid      = sum(Decimal(str(t['amount'])) for t in paid_response.get('Items', []))
        current_debt    = total_purchases - total_paid

        if current_debt <= 0:
            return {
                "statusCode": 400,
                "body": json.dumps({"message": "No tienes deuda pendiente"})
            }

        if amount > current_debt:
            return {
                "statusCode": 400,
                "body": json.dumps({
                    "message": f"El pago excede la deuda. Deuda actual: {current_debt}"
                })
            }

        # 4. Guardar transacción de pago
        transaction_id = str(uuid.uuid4())
        created_at     = datetime.now(timezone.utc).isoformat()

        transaction_table.put_item(Item={
            "uuid":      transaction_id,
            "cardId":    card_id,
            "amount":    str(amount),
            "merchant":  merchant,
            "type":      "PAYMENT_BALANCE",
            "createdAt": created_at
        })

        # 5. Enviar notificación TRANSACTION.PAID
        try:
            sqs.send_message(
                QueueUrl=os.environ.get('NOTIFICATION_QUEUE_URL'),
                MessageBody=json.dumps({
                    "type": "TRANSACTION.PAID",
                    "data": {
                        "date":     created_at,
                        "merchant": merchant,
                        "amount":   str(amount)
                    }
                })
            )
        except Exception as notif_error:
            print(f"[ERROR] Notificación TRANSACTION.PAID falló: {notif_error}")

        return {
            "statusCode": 200,
            "body": json.dumps({
                "message":       "Pago realizado exitosamente",
                "amountPaid":    str(amount),
                "remainingDebt": str(current_debt - amount)
            })
        }

    except Exception as e:
        print(f"❌ Error: {str(e)}")
        return {
            "statusCode": 500,
            "body": json.dumps({"message": f"Error interno: {str(e)}"})
        }