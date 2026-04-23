# .\build.ps1 - Ejecutar desde: transaction-service/terraform/

$base = "..\src"
$zipsDir = "..\zips"

if (-not (Test-Path $zipsDir)) {
    New-Item -ItemType Directory -Path $zipsDir
}

$functions = @{
    "card_get_report"      = "$base\card_get_report"
    "transaction_paid"     = "$base\transaction_paid"
    "transaction_purchase" = "$base\transaction_purchase"
    "transaction_save"     = "$base\transaction_save"
}

foreach ($zip in $functions.Keys) {
    $src = $functions[$zip]

    if (Test-Path $src) {
        Write-Host "Empaquetando $zip..." -ForegroundColor Cyan
        Compress-Archive -Path "$src\*" -DestinationPath "$zipsDir\$zip.zip" -Force
        Write-Host "$zip.zip creado/actualizado OK" -ForegroundColor Green
    } else {
        Write-Host "No se encontro: $src" -ForegroundColor Red
    }
}

Write-Host "`nListo! Ahora corre: terraform apply" -ForegroundColor Yellow