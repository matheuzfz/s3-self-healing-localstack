import boto3
import sys
import time

# Aponta para o LocalStack
s3 = boto3.client(
    's3',
    endpoint_url='http://localhost:4566',
    region_name='sa-east-1',
    aws_access_key_id='test',
    aws_secret_access_key='test'
)

def list_buckets():
    print("Listando buckets disponíveis...")
    response = s3.list_buckets()
    return [b['Name'] for b in response['Buckets']]

def chaos_delete(bucket_name, file_key):
    print(f"\n INICIANDO TESTE: Deletando '{file_key}' do bucket '{bucket_name}'...")
    try:
        s3.delete_object(Bucket=bucket_name, Key=file_key)
        print("Arquivo deletado! O evento deve ter sido disparado.")
        print("Aguarde alguns segundos e verifique os logs da Lambda...")
    except Exception as e:
        print(f"Erro ao tentar deletar: {e}")

if __name__ == "__main__":
    buckets = list_buckets()
    
    prod_bucket = next((b for b in buckets if "production" in b), None)
    
    if not prod_bucket:
        print("Nenhum bucket de produção encontrado. Rode o Terraform primeiro!")
        sys.exit(1)

    print(f"Alvo identificado: {prod_bucket}")
    
    target_file = "arquivo_critico.txt"
    
    chaos_delete(prod_bucket, target_file)