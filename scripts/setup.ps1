# Script de teste para Windows (LocalStack + Terraform)
$ErrorActionPreference = "Stop"

Write-Host "Iniciando setup do ambiente..." -ForegroundColor Cyan

# Subir o LocalStack
if (!(docker ps | Select-String "localstack_main")) {
    Write-Host "Subindo container do LocalStack..."
    docker-compose up -d
    
    Write-Host "Aguardando LocalStack ficar pronto (15s)..."
    Start-Sleep -Seconds 15
} else {
    Write-Host "LocalStack já está rodando."
}

# Terraform Apply
Write-Host "Aplicando Infraestrutura com Terraform..."
Set-Location "infrastructure"

# Inicializa se necessário
if (!(Test-Path ".terraform")) {
    terraform init
}

terraform apply -auto-approve
if ($LASTEXITCODE -ne 0) { Write-Error "Falha no Terraform Apply"; exit }

$prodBucket = terraform output -raw production_bucket_name
$backupBucket = terraform output -raw backup_bucket_name
Set-Location ".."

# 3. Criar arquivos de teste
Write-Host "`nCriando arquivos de teste nos buckets..." -ForegroundColor Cyan

$fileName = "arquivo_critico.txt"
New-Item -Path $fileName -ItemType File -Value "Conteúdo Super Importante v1" -Force | Out-Null

$uploadScript = @"
import boto3
s3 = boto3.client('s3', endpoint_url='http://localhost:4566', region_name='sa-east-1', aws_access_key_id='test', aws_secret_access_key='test')
try:
    s3.upload_file('$fileName', '$backupBucket', '$fileName')
    print(f'Backup criado em {backupBucket}')
    s3.upload_file('$fileName', '$prodBucket', '$fileName')
    print(f'Produção populada em {prodBucket}')
except Exception as e:
    print(f'Erro no upload: {e}')
"@

python -c $uploadScript

# Limpeza local
Remove-Item $fileName

Write-Host "`n✅ Ambiente Pronto!" -ForegroundColor Green
Write-Host "👉 Para testar o Self-Healing, rode: python scripts/chaos_monkey.py" -ForegroundColor Yellow