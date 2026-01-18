import boto3
import os

# Configuração
ENDPOINT = 'http://localhost:4566'
REGION = 'sa-east-1'
FILE_NAME = 'arquivo_critico.txt'
CONTENT = 'Este é um arquivo crítico de produção. Se for deletado, deve voltar!'

# Conexão com LocalStack
s3 = boto3.client('s3', endpoint_url=ENDPOINT, region_name=REGION,
                  aws_access_key_id='test', aws_secret_access_key='test')

def create_local_file():
    print(f"📝 Criando arquivo local: {FILE_NAME}")
    with open(FILE_NAME, 'w') as f:
        f.write(CONTENT)

def get_buckets():
    # Tenta descobrir os nomes dos buckets dinamicamente
    try:
        response = s3.list_buckets()
        buckets = [b['Name'] for b in response['Buckets']]
        prod = next((b for b in buckets if 'production' in b), None)
        backup = next((b for b in buckets if 'backup' in b), None)
        return prod, backup
    except Exception as e:
        print(f"❌ Erro ao listar buckets: {e}")
        return None, None

def upload_files(prod_bucket, backup_bucket):
    if not prod_bucket or not backup_bucket:
        print("❌ Buckets não encontrados! Rode o Terraform primeiro.")
        return

    print(f"🚀 Enviando para Backup: {backup_bucket}")
    s3.upload_file(FILE_NAME, backup_bucket, FILE_NAME)
    
    print(f"🚀 Enviando para Produção: {prod_bucket}")
    s3.upload_file(FILE_NAME, prod_bucket, FILE_NAME)
    print("✅ Upload concluído com sucesso!")

if __name__ == "__main__":
    create_local_file()
    prod, backup = get_buckets()
    
    if prod and backup:
        try:
            upload_files(prod, backup)
        except Exception as e:
            print(f"❌ Erro no upload: {e}")
            print("Dica: Verifique se o LocalStack está rodando (docker ps)")
    
    # Comente a linha abaixo se quiser manter o arquivo txt na sua pasta para ver
    # os.remove(FILE_NAME) 
    # print("🧹 Arquivo local limpo.")