# CI/CD та GitOps розгортання Django-застосунку в AWS EKS з Amazon RDS / Aurora

### Lesson: Універсальний Terraform-модуль баз даних (`modules/rds`) · VPC · EKS · Jenkins · Kaniko · ECR · Helm · Argo CD

---

## 1. Опис проєкту

Проєкт демонструє повний цикл побудови хмарної інфраструктури та автоматизованої доставки (CI/CD + GitOps) для вебзастосунку на **Django** в **Amazon EKS** із використанням керованої реляційної бази даних **Amazon RDS / Aurora**.

### Ключові компоненти архітектури
- **Terraform (IaC):** модульна інфраструктура в AWS (`us-west-2`) — мережа VPC, приватний реєстр ECR, кластер Kubernetes EKS, платформні сервіси Jenkins та Argo CD, підготовка S3/DynamoDB backend та універсальний модуль баз даних `modules/rds`.
- **Amazon RDS / Aurora (`modules/rds`):** універсальний модуль, що перемикається між класичним інстансом `aws_db_instance` та кластером `aws_rds_cluster` через прапор `use_aurora`, автоматично налаштовуючи мережеву ізоляцію (`DB Subnet Group`, `Security Group`) та параметри рушія (`DB Parameter Group`).
- **CI (Jenkins + Kaniko):** збірка Docker-образу всередині Kubernetes-пода без Docker-in-Docker, публікація в Amazon ECR та автоматичне оновлення тегу образу в Git.
- **CD / GitOps (Argo CD + Helm):** декларативна синхронізація Helm-чарту `charts/django-app` із гілки `lesson-db-module`, де застосунок підключений до зовнішнього Amazon RDS без підняття локального контейнера БД у кластері.

### Стек технологій

| Категорія | Технології / сервіси |
|---|---|
| **Cloud & Network** | AWS, VPC (Public/Private Subnets), Internet Gateway, NAT Gateway |
| **Compute & Orchestration** | Amazon EKS, Kubernetes HPA (1–6 подів), AWS EBS CSI Driver (IRSA) |
| **Managed Database** | Amazon RDS (PostgreSQL / MySQL), Amazon Aurora (PostgreSQL / MySQL) |
| **Infrastructure as Code** | Terraform `>= 1.5.0`, S3 + DynamoDB State Backend |
| **Container Registry & Build** | Amazon ECR, Docker, Kaniko |
| **CI/CD & GitOps** | Jenkins (JCasC, Job DSL, Kubernetes Plugin), Argo CD, Helm |
| **Application** | Python 3.11, Django 5.x, `psycopg2-binary` |

---

## 2. Архітектура та потік CI/CD

### 2.1. Взаємодія компонентів інфраструктури

```text
                       ┌─────────────────────────────────────────────┐
                       │                 AWS Cloud (us-west-2)       │
                       │                                             │
  Developer ──push──► GitHub (branch: lesson-db-module)              │
                       │        │                        ▲           │
                       │        ▼ (Webhook / Poll)       │ (git push)│
                       │   ┌─────────┐   Kaniko Build    │           │
                       │   │ Jenkins │ ──────────────────┼──► ECR    │
                       │   └─────────┘                   │           │
                       │        │                        │           │
                       │        ▼ (GitOps Sync)          │           │
                       │   ┌─────────┐                   │           │
                       │   │ Argo CD │ ──────────────────┘           │
                       │   └────┬────┘                               │
                       │        ▼                                    │
                       │   ┌─────────────────────────────────────┐   │
                       │   │ Amazon EKS (Public Subnets)         │   │
                       │   │  └─ Django Pods (Helm + HPA)        │   │
                       │   └──────────────┬──────────────────────┘   │
                       │                  │ TCP 5432 / 3306          │
                       │                  ▼ (Security Group)         │
                       │   ┌─────────────────────────────────────┐   │
                       │   │ Amazon RDS / Aurora (Private Subnets)│  │
                       │   │  ├─ aws_db_subnet_group             │   │
                       │   │  ├─ aws_security_group              │   │
                       │   │  └─ aws_db_parameter_group          │   │
                       │   └─────────────────────────────────────┘   │
                       └─────────────────────────────────────────────┘
```

### 2.2. Послідовність роботи CI/CD
1. Розробник надсилає зміни до гілки `lesson-db-module` у GitHub.
2. **Jenkins** запускає Pipeline `django-app-ci`, створюючи динамічний Kubernetes Agent Pod.
3. Контейнер **Kaniko** збирає Docker-образ із директорії `lesson-8-9/app` та пушить його в **Amazon ECR** з тегом `${BUILD_NUMBER}`.
4. Git-контейнер оновлює `image.tag` у файлі `lesson-8-9/charts/django-app/values.yaml` і комітить зміни в репозиторій.
5. **Argo CD** відстежує гілку `lesson-db-module` та синхронізує Helm-реліз `django-app` у кластері EKS.
6. Поди Django підключаються безпосередньо до керованої бази даних **Amazon RDS** за параметрами з `ConfigMap` та `Secret`.

---

## 3. Структура проєкту

```text
Linux-Administration/
├── .gitignore
├── .vscode/
│   └── settings.json
├── README.md
└── lesson-8-9/
    ├── .terraform.lock.hcl
    ├── README.md                        # Документація проєкту та інструкція до модуля RDS
    ├── backend.tf                       # Конфігурація віддаленого S3 + DynamoDB backend (bootstrap-ready)
    ├── main.tf                          # Головний файл оркестрації Terraform-модулів
    ├── outputs.tf                       # Загальні виводи інфраструктури (VPC, EKS, ECR, RDS, Argo CD)
    ├── variables.tf                     # Вхідні змінні кореневого модуля (github_token, db_password)
    ├── app/
    │   ├── config/
    │   │   ├── __init__.py
    │   │   ├── asgi.py
    │   │   ├── settings.py              # Конфігурація Django та підключення до PostgreSQL через env
    │   │   ├── urls.py
    │   │   └── wsgi.py
    │   ├── .dockerignore
    │   ├── .env.example
    │   ├── .gitignore
    │   ├── Dockerfile                   # Збірка Docker-образу Django-застосунку
    │   ├── Jenkinsfile                  # Декларативний CI-пайплайн (Kaniko build + Helm tag update)
    │   ├── manage.py
    │   └── requirements.txt
    ├── charts/
    │   └── django-app/
    │       ├── templates/
    │       │   ├── configmap.yaml       # Змінні підключення до зовнішнього RDS або локальної БД
    │       │   ├── deployment.yaml      # Deployment для Django-контейнерів
    │       │   ├── hpa.yaml             # HorizontalPodAutoscaler (1–6 подів за CPU 70%)
    │       │   ├── postgres.yaml        # Умовний локальний PostgreSQL (вимкнений при externalDatabase.enabled=true)
    │       │   ├── secret.yaml          # Kubernetes Secret (SECRET_KEY, POSTGRES_PASSWORD)
    │       │   └── service.yaml         # Service типу LoadBalancer (AWS ELB)
    │       ├── Chart.yaml               # Метадані Helm-чарту застосунку
    │       └── values.yaml              # Конфігурація релізу та секція externalDatabase для AWS RDS
    └── modules/
        ├── argo_cd/
        │   ├── charts/
        │   │   ├── templates/
        │   │   │   ├── application.yaml # Argo CD Application маніфест для GitOps
        │   │   │   └── repository.yaml  # Декларативна реєстрація Git-репозиторію в Argo CD
        │   │   ├── Chart.yaml
        │   │   └── values.yaml          # Цільова гілка lesson-db-module та шлях до чарту
        │   ├── argocd.tf                # Розгортання Argo CD та чарту застосунків через Helm
        │   ├── outputs.tf
        │   ├── providers.tf
        │   ├── values.yaml
        │   └── variables.tf
        ├── ecr/
        │   ├── ecr.tf                   # Приватний реєстр Amazon ECR
        │   ├── outputs.tf
        │   └── variables.tf
        ├── eks/
        │   ├── aws_ebs_csi_driver.tf    # OIDC/IRSA роль та політика для AWS EBS CSI Driver
        │   ├── eks.tf                   # Кластер Amazon EKS та Managed Node Group
        │   ├── jenkins_ecr_irsa.tf      # IRSA роль для доступу Jenkins до ECR
        │   ├── outputs.tf
        │   └── variables.tf
        ├── jenkins/
        │   ├── jenkins.tf               # Розгортання Jenkins через Helm та Secret для GitHub
        │   ├── outputs.tf
        │   ├── providers.tf
        │   ├── values.yaml              # JCasC, Job DSL (lesson-8-9/app/Jenkinsfile), Pod Templates
        │   └── variables.tf
        ├── rds/                         # Універсальний модуль керованих баз даних (RDS / Aurora)
        │   ├── aurora.tf                # Aurora Cluster, Cluster Parameter Group та інстанси (use_aurora = true)
        │   ├── outputs.tf               # Виводи (db_endpoint, db_reader_endpoint, db_port, db_type тощо)
        │   ├── rds.tf                   # Стандартний інстанс aws_db_instance (use_aurora = false)
        │   ├── shared.tf                # Спільні ресурси: DB Subnet Group, Security Group, DB Parameter Group
        │   └── variables.tf             # Вхідні змінні з типами, описами та значеннями за замовчуванням
        ├── s3-backend/
        │   ├── dynamodb.tf              # Таблиця DynamoDB для блокування стану Terraform
        │   ├── outputs.tf
        │   ├── s3.tf                    # Версіонований та шифрований S3-бакет для Terraform state
        │   └── variables.tf
        └── vpc/
            ├── outputs.tf
            ├── routes.tf                # Таблиці маршрутизації, Internet Gateway та NAT Gateway
            ├── variables.tf
            └── vpc.tf                   # VPC (10.0.0.0/16), публічні та приватні підмережі
```

---

## 4. Універсальний модуль баз даних (`modules/rds`)

Модуль `modules/rds` інкапсулює створення керованої бази даних в AWS і дозволяє без дублювання коду розгортати як бюджетний однонодовий інстанс **Amazon RDS** (сумісний з AWS Free Tier), так і відмовостійкий кластер **Amazon Aurora**.

### 4.1. Реалізований функціонал
- **Умовна архітектура (`use_aurora`):**
  - При `use_aurora = false` створюється один інстанс `aws_db_instance` із шифруванням сховища `gp3` та автоскейлінгом диска (`allocated_storage` → `max_allocated_storage`).
  - При `use_aurora = true` створюється кластер `aws_rds_cluster`, кластерна група параметрів `aws_rds_cluster_parameter_group` та інстанси `aws_rds_cluster_instance` (1 `writer` при `multi_az = false`, або `writer` + `reader` при `multi_az = true`).
- **Спільні ресурси (`modules/rds/shared.tf`):**
  - `aws_db_subnet_group` — об'єднує приватні підмережі в різних зонах доступності (AZ).
  - `aws_security_group` — відкриває вхідний TCP-трафік лише на порт БД (`5432` для PostgreSQL або `3306` для MySQL, визначається автоматично) для дозволених CIDR-блоків або Security Groups.
  - `aws_db_parameter_group` — налаштовує базові параметри продуктивності та логування (`max_connections`, `log_statement`, `work_mem` для PostgreSQL або еквівалентні `max_connections`, `general_log`, `sort_buffer_size` для MySQL).

### 4.2. Приклад використання модуля (`main.tf`)

```hcl
module "rds" {
  source = "./modules/rds"

  project_name = "django-app"
  environment  = "dev"
  use_aurora   = false

  vpc_id              = module.vpc.vpc_id
  subnet_ids          = module.vpc.private_subnet_ids
  allowed_cidr_blocks = ["10.0.0.0/16"]

  engine           = "postgres"
  engine_version   = "15"
  parameter_family = "postgres15"
  instance_class   = "db.t3.micro"
  multi_az         = false

  db_name         = "djangodb"
  master_username = "dbadmin"
  master_password = var.db_password

  db_parameters = {
    max_connections = "100"
    log_statement   = "all"
    work_mem        = "4096"
  }

  depends_on = [module.vpc]
}
```

### 4.3. Як змінити тип БД, рушій (engine) або клас інстансу

Щоб змінити конфігурацію бази даних, достатньо оновити відповідні аргументи у блоці `module "rds"` у кореневому `main.tf`:

| Сценарій розгортання | `use_aurora` | `engine` | `engine_version` | `parameter_family` | `instance_class` | `multi_az` |
|---|---|---|---|---|---|---|
| **RDS PostgreSQL (Free Tier / Dev)** | `false` | `"postgres"` | `"15"` | `"postgres15"` | `"db.t3.micro"` | `false` |
| **RDS PostgreSQL (Prod High Availability)** | `false` | `"postgres"` | `"15"` | `"postgres15"` | `"db.t3.small"` | `true` |
| **RDS MySQL** | `false` | `"mysql"` | `"8.0"` | `"mysql8.0"` | `"db.t3.micro"` | `false` |
| **Aurora PostgreSQL (Writer only)** | `true` | `"aurora-postgresql"` | `"15.4"` | `"aurora-postgresql15"` | `"db.t3.medium"` | `false` |
| **Aurora PostgreSQL (Writer + Reader)** | `true` | `"aurora-postgresql"` | `"15.4"` | `"aurora-postgresql15"` | `"db.r6g.large"` | `true` |
| **Aurora MySQL** | `true` | `"aurora-mysql"` | `"8.0.mysql_aurora.3.05.2"` | `"aurora-mysql8.0"` | `"db.t3.medium"` | `false` |

> **Примітка:** Сімейство `parameter_family` обов'язково має відповідати обраному `engine` та мажорній версії `engine_version` (наприклад, `postgres15` для RDS PostgreSQL 15 та `aurora-postgresql15` для Aurora PostgreSQL 15).

### 4.4. Опис усіх змінних модуля `modules/rds`

| Назва змінної | Тип | За замовчуванням | Опис |
|---|---|---|---|
| `project_name` | `string` | `"django-app"` | Назва проєкту, використовується як префікс імен ресурсів та у тегах |
| `environment` | `string` | `"dev"` | Середовище розгортання (`dev`, `staging`, `prod`) |
| `use_aurora` | `bool` | `false` | Режим роботи: `true` — створює Aurora Cluster, `false` — стандартний RDS інстанс |
| `vpc_id` | `string` | *(обов'язкова)* | ID VPC, у якій створюється Security Group для бази даних |
| `subnet_ids` | `list(string)` | *(обов'язкова)* | Список ID приватних підмереж (мінімум 2 у різних AZ) для DB Subnet Group |
| `allowed_cidr_blocks` | `list(string)` | `["10.0.0.0/16"]` | Список CIDR-блоків мережі, яким дозволено підключення до порту БД |
| `allowed_security_group_ids` | `list(string)` | `[]` | Список ID Security Groups (наприклад, нод EKS), яким дозволено доступ до БД |
| `engine` | `string` | `"postgres"` | Рушій БД: `postgres`, `mysql` (для RDS) або `aurora-postgresql`, `aurora-mysql` (для Aurora) |
| `engine_version` | `string` | `"15"` | Версія обраного рушія бази даних |
| `parameter_family` | `string` | `"postgres15"` | Сімейство параметрів AWS DB Parameter Group |
| `instance_class` | `string` | `"db.t3.micro"` | Клас обчислювального інстансу БД (`db.t3.micro` для RDS; від `db.t3.medium` для Aurora) |
| `allocated_storage` | `number` | `20` | Початковий обсяг диска в ГБ (застосовується лише для стандартного RDS) |
| `max_allocated_storage` | `number` | `100` | Максимальний обсяг диска в ГБ для автоскейлінгу (лише для стандартного RDS) |
| `db_name` | `string` | `"djangodb"` | Назва початкової бази даних, що створюється при ініціалізації |
| `master_username` | `string` | `"dbadmin"` | Ім'я головного адміністратора бази даних |
| `master_password` | `string` | *(обов'язкова)* | Пароль адміністратора БД (мінімум 8 символів, позначений як `sensitive = true`) |
| `multi_az` | `bool` | `false` | Висока доступність: standby-репліка для RDS або додатковий reader-інстанс для Aurora |
| `backup_retention_period` | `number` | `0` | Термін зберігання автоматичних резервних копій у днях (`0` для сумісності з Free Tier) |
| `skip_final_snapshot` | `bool` | `true` | Пропускати створення фінального знімка при видаленні БД (`true` для dev/тестів) |
| `db_parameters` | `object` | `{100, "all", "4096"}` | Об'єкт базових параметрів БД: `max_connections`, `log_statement`, `work_mem` |

### 4.5. Вихідні параметри модуля (`modules/rds/outputs.tf`)
- `db_endpoint` — основна адреса підключення (Writer endpoint для Aurora або DNS-адреса інстансу для RDS).
- `db_reader_endpoint` — адреса для читання (Reader endpoint для Aurora або основна адреса для RDS).
- `db_port` — TCP-порт бази даних (`5432` або `3306`).
- `db_name` — назва створеної бази даних.
- `db_security_group_id` — ID створеної Security Group.
- `db_subnet_group_name` — назва створеної DB Subnet Group.
- `db_type` — тип розгорнутої архітектури (`Aurora Cluster` або `RDS Instance`).

---

## 5. Інтеграція Django та Helm-чарту з AWS RDS

У Helm-чарті `charts/django-app/` реалізовано перемикання між вбудованим контейнером PostgreSQL та керованим **Amazon RDS**:

- **`charts/django-app/values.yaml`:** додано секцію `externalDatabase`:
  ```yaml
  externalDatabase:
    enabled: true
    host: "django-app-dev-rds.c14ayakww674.us-west-2.rds.amazonaws.com"
    port: 5432
    name: "djangodb"
    user: "dbadmin"
    password: "" # Передається через --set externalDatabase.password=... або Kubernetes Secret
  ```
- **`charts/django-app/templates/postgres.yaml`:** обгорнуто в умову `{{- if not .Values.externalDatabase.enabled }}`, тому при увімкненому RDS зайві `Deployment/db` та `Service/db` у кластері не створюються.
- **`charts/django-app/templates/configmap.yaml` та `secret.yaml`:** автоматично передають `DB_HOST`, `DB_PORT`, `POSTGRES_DB`, `POSTGRES_USER` та `POSTGRES_PASSWORD` у змінні середовища контейнерів Django (`app/config/settings.py`).

---

## 6. Інструкція із запуску та перевірки

### 6.1. Попередні вимоги та змінні середовища
Переконайтеся, що встановлені `terraform >= 1.5.0`, `aws-cli`, `kubectl` та `helm`. Задайте чутливі змінні перед запуском Terraform:

```bash
export TF_VAR_github_token="<YOUR_GITHUB_PAT>"
export TF_VAR_db_password="<YOUR_SECURE_DB_PASSWORD>"
```

*(Для PowerShell використовуйте `$env:TF_VAR_github_token="..."` та `$env:TF_VAR_db_password="..."`).*

### 6.2. Ініціалізація та валідація

```bash
cd lesson-8-9
terraform init
terraform fmt -recursive
terraform validate
```

### 6.3. Налаштування Remote Terraform Backend (`backend.tf`)
За замовчуванням у `backend.tf` конфігурація S3 backend закоментована, щоб забезпечити безпомилкову локальну валідацію та перший запуск без попередньо створеного бакета. Для переходу на віддалений стан:
1. Створіть S3-бакет та таблицю DynamoDB:
   ```bash
   terraform apply -target=module.s3_backend
   ```
2. Розкоментуйте блок `terraform { backend "s3" { ... } }` у `backend.tf` та виконайте міграцію:
   ```bash
   terraform init -migrate-state
   ```

### 6.4. Розгортання модуля RDS або всієї інфраструктури
- **Точковий запуск лише мережі та бази даних:**
  ```bash
  terraform apply -target=module.vpc
  terraform apply -target=module.rds
  ```
- **Повне розгортання всієї інфраструктури:**
  ```bash
  terraform apply
  ```

Після завершення перевірте вихідні параметри та статус інстансу в AWS:
```bash
terraform output
aws rds describe-db-instances --region us-west-2 --query "DBInstances[*].[DBInstanceIdentifier,DBInstanceStatus,Endpoint.Address]" --output table
```

### 6.5. Видалення ресурсів (Cleanup)
Щоб уникнути небажаних витрат в AWS після завершення тестування, видаліть створені ресурси:

```bash
terraform destroy -target=module.rds
terraform destroy -target=module.vpc
# або повне очищення:
terraform destroy
```