import json
import boto3
from boto3.dynamodb.conditions import Attr

dynamodb = boto3.resource('dynamodb')
card_table = dynamodb.Table('card-table')
transaction_table = dynamodb.Table('transaction-table')

def lambda_handler(event, context):
    """
    Recibe:
    {
        "userId": "uuid-del-usuario"
    }
    Busca su tarjeta de crédito PENDING y la activa
    si tiene 10 o más transacciones
    """
    
    try:
        body = json.loads(event['body'])
        user_id = body['userId']
        
        # 1. Buscar la tarjeta de crédito PENDING del usuario
        response = card_table.scan(
            FilterExpression=Attr('user_id').eq(user_id) & 
                           Attr('status').eq('PENDING') & 
                           Attr('type').eq('CREDIT')
        )
        
        cards = response.get('Items', [])
        
        if not cards:
            return {
                "statusCode": 404,
                "body": json.dumps({
                    "message": "No se encontró tarjeta de crédito pendiente para este usuario"
                })
            }
        
        card = cards[0]
        card_id = card['uuid']
        
        # 2. Contar las transacciones de esa tarjeta
        tx_response = transaction_table.scan(
            FilterExpression=Attr('cardId').eq(card_id)
        )
        
        transaction_count = len(tx_response.get('Items', []))
        print(f"Tarjeta {card_id} tiene {transaction_count} transacciones")
        
        # 3. Validar si tiene suficientes transacciones
        if transaction_count < 10:
            return {
                "statusCode": 400,
                "body": json.dumps({
                    "message": f"Necesita 10 transacciones para activar. Tiene: {transaction_count}"
                })
            }
        
        # 4. Activar la tarjeta
        card_table.update_item(
            Key={
                "uuid":      card_id,
                "createdAt": card['createdAt']
            },
            UpdateExpression="SET #s = :status",
            ExpressionAttributeNames={"#s": "status"},
            ExpressionAttributeValues={":status": "ACTIVATED"}
        )
        
        print(f"✅ Tarjeta {card_id} activada exitosamente")
        
        return {
            "statusCode": 200,
            "body": json.dumps({
                "message": "Tarjeta activada exitosamente",
                "cardId":  card_id
            })
        }

    except Exception as e:
        print(f"❌ Error: {str(e)}")
        return {
            "statusCode": 500,
            "body": json.dumps({"message": f"Error interno: {str(e)}"})
        }
