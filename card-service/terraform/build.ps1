# .\build.ps1 - Ejecutar desde: card-service/terraform/

$base = "..\src"
$zipsDir = "..\zips"

# Crea la carpeta zips si no existe
if (-not (Test-Path $zipsDir)) {
    New-Item -ItemType Directory -Path $zipsDir
}

$functions = @{
    "card_activate"        = "$base\card_activate"
    "card_approval_worker" = "$base\card_approval_worker"
    "card_get_cards"       = "$base\card_get_cards"
    "card_request_failed"  = "$base\card_request_failed"
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