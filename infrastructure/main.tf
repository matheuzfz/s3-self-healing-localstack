resource "aws_iam_role" "healer_role" {
  name = "healer_lambda_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# Policy para Lambda(Logs + Acesso total ao S3 para restaurar arquivos)
resource "aws_iam_role_policy" "healer_policy" {
  name = "healer_lambda_policy"
  role = aws_iam_role.healer_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = "*"
      }
    ]
  })
}

# Compactar arquivo Python em Zip
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "../src/healer_lambda"
  output_path = "${path.module}/healer_payload.zip"
}

resource "aws_lambda_function" "healer" {
  filename      = data.archive_file.lambda_zip.output_path
  function_name = "SelfHealingFunction"
  role          = aws_iam_role.healer_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.9"
  timeout       = 10

  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  # Nome dos buckets para o Python
  environment {
    variables = {
      BACKUP_BUCKET_NAME = var.backup_bucket_name
      PROD_BUCKET_NAME   = var.prod_bucket_name
    }
  }
}

resource "aws_sns_topic" "alerts" {
  name = "s3-deletion-alerts"
}

resource "aws_sns_topic_subscription" "lambda_subscription" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.healer.arn
}

resource "aws_lambda_permission" "sns_invoke" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.healer.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.alerts.arn
}

resource "aws_s3_bucket" "production" {
  bucket = var.prod_bucket_name
}

resource "aws_s3_bucket" "backup" {
  bucket = var.backup_bucket_name
}

# Event Notification trigger ---
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.production.id

  topic {
    topic_arn     = aws_sns_topic.alerts.arn
    events        = ["s3:ObjectRemoved:Delete"]
  }
  
  depends_on = [aws_lambda_permission.sns_invoke] 
}