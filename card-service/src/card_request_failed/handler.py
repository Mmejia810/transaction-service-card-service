import json
import uuid
import boto3
from datetime import datetime, timezone

dynamodb = boto3.resource('dynamodb')
error_table = dynamodb.Table('card-table-error')

def lambda_handler(event, context):
    """
    Recibe mensajes que fallaron 3 veces en la cola principal
    Los guarda en la tabla de errores para auditoría
    """
    
    for record in event['Records']:
        try:
            error_id = str(uuid.uuid4())
            created_at = datetime.now(timezone.utc).isoformat()
            
            error_item = {
                "uuid":            error_id,
                "originalMessage": record['body'],   # guardamos el mensaje original
                "errorSource":     "create-request-card-sqs",
                "createdAt":       created_at
            }
            
            error_table.put_item(Item=error_item)
            print(f"⚠️ Error guardado en auditoría: {error_id}")

        except Exception as e:
            print(f"❌ Error guardando en tabla de errores: {str(e)}")
            raise e

    return {"statusCode": 200}