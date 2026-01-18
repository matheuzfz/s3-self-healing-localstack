import json
import boto3
import os
import logging
import urllib.parse

logger = logging.getLogger()
logger.setLevel(logging.INFO)

s3 = boto3.client('s3')

def lambda_handler(event, context):
    # Função acionada via SNS quando um objeto é deletado no S3.
    logger.info("Evento recebido: %s", json.dumps(event))

    try:
        sns_message = event['Records'][0]['Sns']['Message']
        s3_event = json.loads(sns_message)

        s3_record = s3_event['Records'][0]['s3']
        deleted_bucket = s3_record['bucket']['name']
        deleted_key = urllib.parse.unquote_plus(s3_record['object']['key'], encoding='utf-8')

        logger.info(f"ALERTA: Arquivo '{deleted_key}' foi deletado do bucket '{deleted_bucket}'")

        backup_bucket = os.environ['BACKUP_BUCKET_NAME']
        prod_bucket = os.environ['PROD_BUCKET_NAME']

        if deleted_bucket != prod_bucket:
            logger.warning("Evento ignorado: O bucket afetado não é o de produção monitorado.")
            return

        logger.info(f"Iniciando protocolo de recuperação buscando em: {backup_bucket}...")

        try:
            copy_source = {'Bucket': backup_bucket, 'Key': deleted_key}
            
            s3.copy_object(
                CopySource=copy_source,
                Bucket=prod_bucket,
                Key=deleted_key
            )
            
            logger.info(f"SUCESSO: Arquivo '{deleted_key}' restaurado automaticamente em '{prod_bucket}'.")
            return {
                'statusCode': 200,
                'body': json.dumps(f"Arquivo {deleted_key} recuperado com sucesso.")
            }

        except s3.exceptions.ClientError as e:
            error_code = e.response['Error']['Code']
            if error_code == "404" or error_code == "NoSuchKey":
                logger.error(f"FALHA CRÍTICA: O arquivo '{deleted_key}' não existe no backup! Impossível recuperar.")
            else:
                logger.error(f"Erro desconhecido ao tentar copiar: {str(e)}")
            raise e

    except Exception as e:
        logger.error(f"Erro ao processar a função Lambda: {str(e)}")
        raise e