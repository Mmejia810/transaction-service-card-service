import json
import boto3
from boto3.dynamodb.conditions import Attr

dynamodb = boto3.resource('dynamodb')
card_table = dynamodb.Table('card-table')
transaction_table = dynamodb.Table('transaction-table')

def lambda_handler(event, context):
    try:
        body    = json.loads(event['body'])
        user_id = body['userId']

        # Buscar la tarjeta de crédito PENDING del usuario
        credit_response = card_table.scan(
            FilterExpression=Attr('user_id').eq(user_id) &
                             Attr('status').eq('PENDING') &
                             Attr('type').eq('CREDIT')
        )
        cards = credit_response.get('Items', [])

        if not cards:
            return {
                "statusCode": 404,
                "body": json.dumps({
                    "message": "No se encontró tarjeta de crédito pendiente para este usuario"
                })
            }

        card    = cards[0]
        card_id = card['uuid']

        # Buscar la tarjeta DÉBITO del usuario
        debit_response = card_table.scan(
            FilterExpression=Attr('user_id').eq(user_id) &
                             Attr('type').eq('DEBIT')
        )
        debit_cards = debit_response.get('Items', [])

        if not debit_cards:
            return {
                "statusCode": 404,
                "body": json.dumps({"message": "No se encontró tarjeta débito del usuario"})
            }

        debit_card_id = debit_cards[0]['uuid']

        # Contar transacciones PURCHASE de la tarjeta débito
        tx_response = transaction_table.scan(
            FilterExpression=Attr('cardId').eq(debit_card_id) &
                             Attr('type').eq('PURCHASE')
        )

        transaction_count = len(tx_response.get('Items', []))
        print(f"Tarjeta débito {debit_card_id} tiene {transaction_count} compras")

        # Validar si tiene suficientes transacciones
        if transaction_count < 10:
            return {
                "statusCode": 400,
                "body": json.dumps({
                    "message": f"Necesita 10 transacciones para activar. Tiene: {transaction_count}"
                })
            }

        # Activar la tarjeta de crédito
        card_table.update_item(
            Key={
                "uuid":      card_id,
                "createdAt": card['createdAt']
            },
            UpdateExpression="SET #s = :status",
            ExpressionAttributeNames={"#s": "status"},
            ExpressionAttributeValues={":status": "ACTIVATED"}
        )

        return {
            "statusCode": 200,
            "body": json.dumps({
                "message": "Tarjeta de crédito activada exitosamente",
                "cardId":  card_id
            })
        }

    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            "statusCode": 500,
            "body": json.dumps({"message": f"Error interno: {str(e)}"})
        }