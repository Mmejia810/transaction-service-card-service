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
        card_id  = event['pathParameters']['card_id']
        body     = json.loads(event['body'])
        amount   = Decimal(str(body['amount']))
        merchant = body.get('merchant', 'SAVING')

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
        balance   = Decimal(str(card['balance']))

        # 2. Solo débito
        if card_type != "DEBIT":
            return {
                "statusCode": 400,
                "body": json.dumps({"message": "Solo se puede abonar saldo a tarjetas débito"})
            }

        # 3. Sumar saldo
        new_balance = balance + amount

        card_table.update_item(
            Key={
                "uuid":      card['uuid'],
                "createdAt": card['createdAt']
            },
            UpdateExpression="SET balance = :new_balance",
            ExpressionAttributeValues={":new_balance": str(new_balance)}
        )

        # 4. Guardar transacción
        transaction_id = str(uuid.uuid4())
        created_at     = datetime.now(timezone.utc).isoformat()

        transaction_table.put_item(Item={
            "uuid":      transaction_id,
            "cardId":    card_id,
            "amount":    str(amount),
            "merchant":  merchant,
            "type":      "SAVING",
            "createdAt": created_at
        })

        return {
            "statusCode": 200,
            "body": json.dumps({
                "message":    "Saldo agregado exitosamente",
                "newBalance": str(new_balance)
            })
        }

    except Exception as e:
        print(f"❌ Error: {str(e)}")
        return {
            "statusCode": 500,
            "body": json.dumps({"message": f"Error interno: {str(e)}"})
        }