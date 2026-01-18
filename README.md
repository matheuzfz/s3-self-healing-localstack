# 🛡️ S3 Self-Healing Infrastructure (LocalStack Simulation)

![Terraform](https://img.shields.io/badge/Terraform-IaC-purple?logo=terraform)
![Python](https://img.shields.io/badge/Python-Boto3-blue?logo=python)
![LocalStack](https://img.shields.io/badge/AWS-Emulation-orange)
![Docker](https://img.shields.io/badge/Docker-Container-blue?logo=docker)
![CI Pipeline](https://github.com/matheuzfz/s3-self-healing-localstack/actions/workflows/ci-pipeline.yml/badge.svg)

Este projeto implementa uma arquitetura de referência para **Resiliência e Auto-Recuperação (Self-Healing)** em ambientes de nuvem. A solução monitora continuamente a integridade de dados críticos armazenados em um Bucket S3 e reage automaticamente a eventos de perda de dados (deleção acidental ou maliciosa) sem intervenção humana, restaurando o estado original em segundos.

Todo o ambiente é simulado localmente utilizando **LocalStack**, garantindo paridade com a AWS real sem custos de infraestrutura.

## 🏗️ Arquitetura da Solução

O sistema baseia-se em uma **Arquitetura Orientada a Eventos (Event-Driven Architecture)**, eliminando a necessidade de *polling* (verificação contínua) e otimizando o consumo de recursos computacionais.

:::mermaid
graph TD
    A[User / External System] -->|DELETE Action| B[S3 Bucket - Production]
    B -->|Event: s3:ObjectRemoved| C[SNS Topic - Alerts]
    C -->|Trigger| D[Lambda Function - Healer]
    D -->|Read Immutable Copy| E[S3 Bucket - Backup]
    D -->|Restore Object| B
    D -->|Audit Log| F[CloudWatch Logs]
:::

### Fluxo de Dados:

* ***Gatilho:*** Uma ação de DELETE é detectada no Bucket de Produção.
* ***Notificação:*** O S3 publica um evento assíncrono no tópico Amazon SNS.
* ***Processamento:*** O SNS aciona a função AWS Lambda (Python), passando o payload do evento.
* ***Recuperação:*** A Lambda identifica o objeto perdido, localiza sua cópia no Bucket de Backup e restaura o arquivo no Bucket de Produção.
* ***Observabilidade:*** Todas as ações são registradas no Amazon CloudWatch para auditoria.

## Tecnologias Utilizadas

```Terraform (IaC):``` Provisionamento declarativo da infraestrutura (IaC), gerenciamento de estado e dependências entre recursos (Buckets, Policies, Triggers).

```AWS Lambda (Python):``` Execução da lógica de negócio serverless para processamento do evento de recuperação e manipulação do SDK da AWS.

```Boto3 SDK:``` Biblioteca Python utilizada dentro da Lambda para interagir com os serviços AWS (S3 Operations).

```Amazon SNS:``` Camada de mensageria para desacoplar o evento de armazenamento (S3) da lógica de processamento (Lambda), permitindo arquitetura Fan-out.

```LocalStack:``` Emulação completa das APIs da AWS em ambiente local via Docker, permitindo desenvolvimento e testes de integração sem custos de cloud.

```Docker Compose:``` Orquestração do ambiente local.

## Estrutura do Repositório

O projeto segue uma estrutura modular, separando a definição de infraestrutura (Terraform) da lógica da aplicação (Python).

```text
.
├── infrastructure/         # IaC com Terraform
│   ├── main.tf             # Definição completa (S3, SNS, Lambda e IAM)
│   ├── variables.tf        # Variáveis de entrada (Nomes dos buckets, região)
│   ├── outputs.tf          # Outputs para consumo externo (ARNs, Nomes)
│   ├── provider.tf         # Configuração do Provider AWS/LocalStack
│   ├── terraform.tfstate   # Estado da infraestrutura (Local)
│   └── healer_payload.zip  # Artefato zipado da Lambda (Gerado automaticamente)
│
├── scripts/                # Scripts de Automação e Teste
│   ├── chaos_monkey.py     # Script Python para deletar arquivos (Caos)
│   ├── seed_buckets.py     # Script para popular os buckets com dados
│   ├── setup.ps1           # Script PowerShell de inicialização do ambiente
│   └── requirements.txt    # Dependências para rodar os scripts locais
│
├── src/                    # Código Fonte da Aplicação Serverless
│   └── healer_lambda/
│       ├── lambda_function.py  # Lógica de auto-recuperação
│       └── requirements.txt    # Dependências da Lambda (vazio se usar stdlib)
│
├── docker-compose.yml      # Definição do container LocalStack
├── .gitignore              # Arquivos ignorados pelo Git
└── README.md               # Documentação do projeto
```

## 💡 Competências e Diferenciais Técnicos

Este projeto vai além do básico, servindo como uma demonstração prática de maturidade em engenharia de software e operações (DevOps/SRE):

* **Arquitetura Orientada a Eventos (EDA):** Domínio na criação de sistemas desacoplados e reativos, utilizando **Amazon SNS** para orquestrar a comunicação assíncrona entre o armazenamento (S3) e a computação (Lambda).
* **Infrastructure as Code (IaC) Avançado:** Uso profissional do **Terraform** para gerenciar todo o ciclo de vida da infraestrutura, lidando com dependências complexas, *State Management* e injeção de variáveis, eliminando configurações manuais (*ClickOps*).
* **Mentalidade SRE (Site Reliability Engineering):** Implementação de padrões de *Self-Healing* (Auto-Recuperação), priorizando a automação de correções para garantir a resiliência e a continuidade do negócio sem intervenção humana.
* **Desenvolvimento Cloud-Native Econômico:** Capacidade de emular ambientes AWS complexos localmente com **LocalStack e Docker**, demonstrando preocupação com eficiência de custos (FinOps) e velocidade de desenvolvimento (Developer Experience).
* **Segurança e IAM:** Aplicação do princípio do privilégio mínimo (*Least Privilege*), configurando Roles e Policies específicas para que cada serviço acesse apenas o necessário.
