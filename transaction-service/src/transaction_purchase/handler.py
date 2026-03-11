import json
import uuid
import boto3
import os
from datetime import datetime, timezone
from boto3.dynamodb.conditions import Attr
from decimal import Decimal

dynamodb = boto3.resource('dynamodb')
card_table        = dynamodb.Table(os.environ['CARD_TABLE'])
transaction_table = dynamodb.Table(os.environ['TRANSACTION_TABLE'])

def lambda_handler(event, context):
    try:
        body     = json.loads(event['body'])
        card_id  = body['cardId']
        amount   = Decimal(str(body['amount']))
        merchant = body['merchant']

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
        status    = card['status']
        balance   = Decimal(str(card['balance']))

        # 2. Validar que esté activa
        if status != "ACTIVATED":
            return {
                "statusCode": 400,
                "body": json.dumps({"message": "La tarjeta no está activada"})
            }

        # 3. Validar saldo
        if card_type == "DEBIT":
            if balance < amount:
                return {
                    "statusCode": 400,
                    "body": json.dumps({
                        "message": f"Saldo insuficiente. Disponible: {balance}, Requerido: {amount}"
                    })
                }
            new_balance = balance - amount

            # Actualizar balance en card-table
            card_table.update_item(
                Key={
                    "uuid":      card['uuid'],
                    "createdAt": card['createdAt']
                },
                UpdateExpression="SET balance = :new_balance",
                ExpressionAttributeValues={":new_balance": str(new_balance)}
            )

        elif card_type == "CREDIT":
            used_response = transaction_table.scan(
                FilterExpression=Attr('cardId').eq(card_id) & Attr('type').eq('PURCHASE')
            )
            paid_response = transaction_table.scan(
                FilterExpression=Attr('cardId').eq(card_id) & Attr('type').eq('PAYMENT_BALANCE')
            )
            total_used = sum(Decimal(str(t['amount'])) for t in used_response.get('Items', []))
            total_paid = sum(Decimal(str(t['amount'])) for t in paid_response.get('Items', []))
            available  = balance - (total_used - total_paid)

            if amount > available:
                return {
                    "statusCode": 400,
                    "body": json.dumps({
                        "message": f"Cupo insuficiente. Disponible: {available}, Requerido: {amount}"
                    })
                }

        # 4. Guardar transacción
        transaction_id = str(uuid.uuid4())
        created_at     = datetime.now(timezone.utc).isoformat()

        transaction_table.put_item(Item={
            "uuid":      transaction_id,
            "cardId":    card_id,
            "amount":    str(amount),
            "merchant":  merchant,
            "type":      "PURCHASE",
            "createdAt": created_at
        })

        return {
            "statusCode": 200,
            "body": json.dumps({
                "message":       "Compra realizada exitosamente",
                "transactionId": transaction_id,
                "amount":        str(amount),
                "merchant":      merchant
            })
        }

    except Exception as e:
        print(f"❌ Error: {str(e)}")
        return {
            "statusCode": 500,
            "body": json.dumps({"message": f"Error interno: {str(e)}"})
        }