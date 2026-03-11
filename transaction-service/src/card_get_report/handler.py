import json
import csv
import uuid
import boto3
import os
from datetime import datetime, timezone
from boto3.dynamodb.conditions import Attr
from io import StringIO

dynamodb = boto3.resource('dynamodb')
s3 = boto3.client('s3')
transaction_table = dynamodb.Table(os.environ['TRANSACTION_TABLE'])

BUCKET_NAME = os.environ['REPORTS_BUCKET']

def lambda_handler(event, context):
    try:
        card_id = event['pathParameters']['card_id']
        body    = json.loads(event['body'])
        start   = body['start']
        end     = body['end']

        # 1. Obtener todas las transacciones de esa tarjeta
        response = transaction_table.scan(
            FilterExpression=Attr('cardId').eq(card_id)
        )
        transactions = response.get('Items', [])

        # 2. Filtrar por rango de fechas
        filtered = [
            t for t in transactions
            if start <= t['createdAt'] <= end
        ]

        if not filtered:
            return {
                "statusCode": 404,
                "body": json.dumps({"message": "No se encontraron transacciones en ese rango"})
            }

        # 3. Generar el CSV en memoria
        output = StringIO()
        writer = csv.DictWriter(output, fieldnames=['uuid', 'cardId', 'amount', 'merchant', 'type', 'createdAt'])
        writer.writeheader()
        writer.writerows(filtered)
        csv_content = output.getvalue()

        # 4. Subir el CSV a S3
        file_name = f"reports/{card_id}/{str(uuid.uuid4())}.csv"
        s3.put_object(
            Bucket      = BUCKET_NAME,
            Key         = file_name,
            Body        = csv_content,
            ContentType = "text/csv"
        )

        # 5. Generar URL publica
        report_url = f"https://{BUCKET_NAME}.s3.amazonaws.com/{file_name}"

        return {
            "statusCode": 200,
            "body": json.dumps({
                "message":    "Reporte generado exitosamente",
                "reportUrl":  report_url,
                "totalItems": len(filtered)
            })
        }

    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            "statusCode": 500,
            "body": json.dumps({"message": f"Error interno: {str(e)}"})
        }