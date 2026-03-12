# Banco Cerdos - Card & Transaction Service 🏦

Repositorio que contiene dos microservicios del sistema bancario **Banco Cerdos**:

- **Card Service** → creación y activación de tarjetas
- **Transaction Service** → compras, abonos, pagos y reportes

---

## Estructura del repositorio

```
├── card-service/
│   ├── src/
│   │   ├── card_approval_worker/
│   │   │   └── handler.py
│   │   ├── card_activate/
│   │   │   └── handler.py
│   │   ├── card_request_failed/
│   │   │   └── handler.py
│   │   └── zips/
│   └── terraform/
│       ├── main.tf
│       ├── dynamodb.tf
│       ├── sqs.tf
│       ├── iam.tf
│       ├── lambda.tf
│       └── api_gateway.tf
│
└── transaction-service/
    ├── src/
    │   ├── transaction_purchase/
    │   │   └── handler.py
    │   ├── transaction_save/
    │   │   └── handler.py
    │   ├── transaction_paid/
    │   │   └── handler.py
    │   ├── card_get_report/
    │   │   └── handler.py
    │   └── zips/
    └── terraform/
        ├── main.tf
        ├── dynamodb.tf
        ├── iam.tf
        ├── lambda.tf
        └── api_gateway.tf
```

---

# Card Service

Microservicio encargado de la creación y activación de tarjetas débito y crédito.

## Arquitectura

```
Usuario se registra (User Service)
        ↓
Envía mensaje a SQS (create-request-card-sqs)
        ↓
card-approval-worker escucha la cola
        ↓
Genera score aleatorio → calcula monto
        ↓
DEBIT  → status: ACTIVATED, balance: 0
CREDIT → status: PENDING,   balance: cupo aprobado
        ↓
Guarda en DynamoDB (card-table)

Si falla 3 veces → DLQ → card-request-failed → card-table-error
```

## Componentes AWS

| Componente | Nombre | Descripción |
|---|---|---|
| API Gateway | card-service-api | Expone los endpoints HTTP |
| SQS | create-request-card-sqs | Cola principal de solicitudes |
| SQS DLQ | error-create-request-card-sqs | Cola de mensajes fallidos |
| Lambda | card-approval-worker | Procesa solicitudes y crea tarjetas |
| Lambda | card-activate-lambda | Activa tarjetas de crédito |
| Lambda | card-request-failed | Maneja errores de la DLQ |
| DynamoDB | card-table | Almacena las tarjetas |
| DynamoDB | card-table-error | Almacena errores de procesamiento |

## Endpoints

### POST /card/activate
Activa una tarjeta de crédito cuando el usuario tiene 10 o más transacciones.

**Request:**
```json
{
    "userId": "b31e7bd3-0b03-48be-a720-de1d4ca4a96c"
}
```

**Response exitoso:**
```json
{
    "message": "Tarjeta activada exitosamente",
    "cardId": "48a8d8d1-73e1-41ed-92e4-6157377542e9"
}
```

**Response con transacciones insuficientes:**
```json
{
    "message": "Necesita 10 transacciones para activar. Tiene: 3"
}
```

## Mensajes SQS

### Crear tarjeta débito
```json
{
    "userId": "b31e7bd3-0b03-48be-a720-de1d4ca4a96c",
    "request": "DEBIT"
}
```

### Crear tarjeta crédito
```json
{
    "userId": "b31e7bd3-0b03-48be-a720-de1d4ca4a96c",
    "request": "CREDIT"
}
```

## Algoritmo de aprobación de crédito

```
score  = random(0, 100)
monto  = 100 + (score / 100) * 9,999,900
```

| Score | Monto aprobado |
|---|---|
| 0 | $100 |
| 50 | $5,000,050 |
| 100 | $10,000,000 |

## Modelo de datos - card-table

```json
{
    "uuid": "48a8d8d1-73e1-41ed-92e4-6157377542e9",
    "user_id": "7b92b92b-88db-4f7f-899b-de0fc2f2f738",
    "type": "DEBIT",
    "status": "ACTIVATED",
    "balance": "1000",
    "score": 75,
    "createdAt": "2026-03-10T14:30:15.123Z"
}
```

| Campo | Tipo | Descripción |
|---|---|---|
| uuid | String (PK) | Identificador único de la tarjeta |
| user_id | String | ID del usuario propietario |
| type | String | DEBIT o CREDIT |
| status | String | ACTIVATED o PENDING |
| balance | String | Saldo disponible (débito) o cupo (crédito) |
| score | Number | Score de aprobación generado aleatoriamente |
| createdAt | String (SK) | Fecha de creación en formato ISO 8601 |

---

# Transaction Service

Microservicio encargado de gestionar las transacciones financieras y generación de reportes.

## Arquitectura

```
Usuario realiza operación
        ↓
API Gateway recibe la petición
        ↓
Lambda procesa la lógica de negocio
        ↓
Valida saldo/cupo en card-table
        ↓
Guarda transacción en transaction-table
        ↓
Actualiza balance en card-table (si aplica)
```

## Componentes AWS

| Componente | Nombre | Descripción |
|---|---|---|
| API Gateway | transaction-service-api | Expone los endpoints HTTP |
| Lambda | card-purchase-lambda | Procesa compras con débito y crédito |
| Lambda | card-transaction-save-lambda | Abona saldo a tarjetas débito |
| Lambda | card-paid-credit-card-lambda | Procesa pagos de tarjeta crédito |
| Lambda | card-get-report-lambda | Genera reportes CSV de transacciones |
| DynamoDB | transaction-table | Almacena todas las transacciones |
| S3 | transactions-report-bucket | Almacena los reportes CSV generados |

## Endpoints

### POST /transactions/purchase
Realiza una compra con tarjeta débito o crédito.

**Request:**
```json
{
    "merchant": "Tienda patito feliz",
    "cardId": "39fe6315-2dd5-4f2d-9160-22f1c96a05c8",
    "amount": 1000
}
```

**Response exitoso:**
```json
{
    "message": "Compra realizada exitosamente",
    "transactionId": "33d19bcb-148f-47b1-b963-77602eaf7ae5",
    "amount": "1000",
    "merchant": "Tienda patito feliz"
}
```

**Response saldo insuficiente:**
```json
{
    "message": "Saldo insuficiente. Disponible: 5000, Requerido: 10000"
}
```

---

### POST /transactions/save/{card_id}
Abona saldo a una tarjeta débito.

**Request:**
```json
{
    "merchant": "SAVING",
    "amount": 1000
}
```

**Response exitoso:**
```json
{
    "message": "Saldo agregado exitosamente",
    "newBalance": "6000"
}
```

---

### POST /card/paid/{card_id}
Paga la deuda de una tarjeta de crédito.

**Request:**
```json
{
    "merchant": "PSE",
    "amount": 1000
}
```

**Response exitoso:**
```json
{
    "message": "Pago realizado exitosamente",
    "amountPaid": "1000",
    "remainingDebt": "500"
}
```

---

### POST /report/{card_id}
Genera un reporte CSV con las transacciones en un rango de fechas y lo sube a S3.

**Request:**
```json
{
    "start": "2026-03-01T00:00:00.000000+00:00",
    "end": "2026-03-31T23:59:59.000000+00:00"
}
```

**Response exitoso:**
```json
{
    "message": "Reporte generado exitosamente",
    "reportUrl": "https://transactions-report-bucket-xxx.s3.amazonaws.com/reports/card-id/xxx.csv",
    "totalItems": 5
}
```

## Lógica de negocio

### Compra con tarjeta débito
```
si amount > balance → error saldo insuficiente
si no → balance = balance - amount
```

### Compra con tarjeta crédito
```
cupo disponible = cupo total - (total compras - total pagos)
si amount > cupo disponible → error cupo insuficiente
si no → registra la transacción
```

### Pago de tarjeta crédito
```
deuda actual = total compras - total pagos
si amount > deuda actual → error pago excede deuda
si no → registra transacción PAYMENT_BALANCE
```

## Modelo de datos - transaction-table

```json
{
    "uuid": "33d19bcb-148f-47b1-b963-77602eaf7ae5",
    "cardId": "48a8d8d1-73e1-41ed-92e4-6157377542e9",
    "amount": "100",
    "merchant": "Tienda doña clotilde",
    "type": "PURCHASE",
    "createdAt": "2026-03-10T14:30:15.123Z"
}
```

| Campo | Tipo | Descripción |
|---|---|---|
| uuid | String (PK) | Identificador único de la transacción |
| cardId | String | ID de la tarjeta asociada |
| amount | String | Monto de la transacción |
| merchant | String | Nombre del comercio |
| type | String | PURCHASE, SAVING o PAYMENT_BALANCE |
| createdAt | String (SK) | Fecha de creación en formato ISO 8601 |

## Tipos de transacción

| Tipo | Descripción | Tarjeta |
|---|---|---|
| PURCHASE | Compra realizada | DEBIT o CREDIT |
| SAVING | Abono de saldo | Solo DEBIT |
| PAYMENT_BALANCE | Pago de deuda | Solo CREDIT |

---

# Despliegue

## Prerequisitos
- Terraform >= 1.0
- AWS CLI configurado con credenciales válidas
- Python 3.11

## Orden de despliegue

> ⚠️ El card-service debe desplegarse primero ya que transaction-service depende de `card-table`.

### 1. Card Service
```bash
cd card-service/terraform
terraform init
terraform plan
terraform apply
```

### 2. Transaction Service
```bash
cd transaction-service/terraform
terraform init
terraform plan
terraform apply
```

## Destruir recursos

```bash
# Transaction Service primero
cd transaction-service/terraform
aws s3 rm s3://transactions-report-bucket-XXXXX --recursive
terraform destroy

# Luego Card Service
cd card-service/terraform
terraform destroy
```

---

# Integración entre servicios

```
User Service ──── SQS ────► Card Service
                                  │
                                  │ card-table
                                  ▼
                         Transaction Service
                                  │
                                  │ reportes CSV
                                  ▼
                              S3 Bucket
```
