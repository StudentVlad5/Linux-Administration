# CI/CD та GitOps розгортання Django-застосунку в AWS EKS

### Lesson 8–9 | Terraform · Jenkins · Kaniko · Amazon ECR · Helm · Argo CD

---

## Опис проєкту

Цей проєкт демонструє реалізацію повного циклу **CI/CD та GitOps** для автоматизованого розгортання вебзастосунку на базі **Django** у керованому Kubernetes-кластері **Amazon EKS**.

Основна мета - побудувати автоматизований процес доставки змін, який дозволяє розробнику оновити код у GitHub, після чого система самостійно збирає Docker-образ, завантажує його до Amazon ECR, оновлює конфігурацію Helm-чарта та синхронізує нову версію застосунку з Kubernetes-кластером.

Для реалізації використано:

- **Terraform** - автоматизоване створення хмарної інфраструктури AWS.
- **Helm** - встановлення та конфігурація Jenkins і Argo CD у Kubernetes.
- **Jenkins (JCasC + Job DSL)** - декларативне налаштування CI-сервера та автоматизація збірок.
- **Kaniko** - збирання Docker-образів без використання Docker daemon.
- **Amazon ECR** - приватне сховище Docker-образів.
- **Argo CD** - декларативне управління розгортанням за методологією GitOps.
- **Kubernetes HPA** - автоматичне горизонтальне масштабування застосунку.

У результаті створено конвеєр, у якому оновлення коду в GitHub автоматично запускає процес збирання та розгортання нової версії Django-застосунку.

---

## Архітектура та робочий процес (GitOps Flow)

```text
                  [ Developer ]
                        |
                        | Git Push
                        v
              [ GitHub Repository ]
                 Branch: lesson-8-9
                        |
                        | 1. Trigger Build
                        v
                [ Jenkins on EKS ]
               JCasC + Kubernetes Agent
                   (Kaniko + Git)
                        |
              +---------+---------+
              |                   |
              | 2. Build Image    | 3. Update image.tag
              |                   |
              v                   v
        [ Amazon ECR ]       [ GitHub Repository ]
        django-app:TAG       charts/django-app/
                             values.yaml
                                  |
                                  | 4. Git Change Detection
                                  v
                            [ Argo CD on EKS ]
                                  |
                                  | 5. Auto-Sync
                                  v
                          [ Kubernetes Cluster ]
                                  |
                  +---------------+---------------+
                  |               |               |
                  v               v               v
             [ Django ]     [ PostgreSQL ]     [ HPA ]
             Deployment     Deployment         1..6 Pods
                  |
                  v
           [ AWS LoadBalancer ]
                  |
                  v
             [ Web Browser ]
```

### Послідовність роботи CI/CD

1. **Git Push:** розробник надсилає зміни до GitHub.
2. **Trigger Build:** Jenkins запускає CI-пайплайн.
3. **Build & Push:** Kaniko збирає Docker-образ та завантажує його до Amazon ECR з унікальним тегом `${BUILD_NUMBER}`.
4. **Update Helm Chart:** Jenkins автоматично змінює тег Docker-образу у `values.yaml` та відправляє коміт до GitHub.
5. **GitOps Synchronization:** Argo CD виявляє зміни в Git-репозиторії.
6. **Deployment:** Argo CD автоматично синхронізує Helm-чарт із Kubernetes-кластером.
7. **Rolling Update:** Kubernetes поступово замінює старі поди новою версією застосунку.

---

## Технологічний стек

| Категорія                 | Технології та сервіси                  |
| ------------------------- | -------------------------------------- |
| Хмарна інфраструктура     | AWS, Amazon EKS, EC2, VPC, NAT Gateway |
| Infrastructure as Code    | Terraform                              |
| Віддалений стан Terraform | Amazon S3, DynamoDB                    |
| Контейнерний реєстр       | Amazon ECR                             |
| CI/CD                     | Jenkins                                |
| Збирання Docker-образів   | Kaniko                                 |
| Контейнеризація           | Docker                                 |
| Оркестрація               | Kubernetes                             |
| Керування пакетами        | Helm                                   |
| GitOps                    | Argo CD                                |
| Автомасштабування         | Kubernetes HPA                         |
| Збір метрик               | Metrics Server                         |
| Постійне сховище          | Amazon EBS, EBS CSI Driver             |
| Застосунок                | Python, Django, Gunicorn               |
| База даних                | PostgreSQL                             |
| Контроль версій           | Git, GitHub                            |

---

## Структура проєкту

```text
lesson-8-9/
├── app/
│   ├── config/
│   │   ├── __init__.py
│   │   ├── asgi.py
│   │   ├── settings.py                  # Конфігурація Django та підключення до PostgreSQL
│   │   ├── urls.py
│   │   └── wsgi.py
│   ├── .dockerignore
│   ├── .env.example
│   ├── .gitignore
│   ├── Dockerfile                       # Збірка Docker-образу Django-застосунку
│   ├── Jenkinsfile                      # Декларативний CI-пайплайн (Kaniko build + Git tag update)
│   ├── manage.py
│   └── requirements.txt
├── charts/
│   └── django-app/
│       ├── templates/
│       │   ├── configmap.yaml           # Відкриті змінні середовища застосунку (ConfigMap)
│       │   ├── deployment.yaml          # Deployment для Django-контейнерів
│       │   ├── hpa.yaml                 # HorizontalPodAutoscaler (1–6 подів за CPU)
│       │   ├── postgres.yaml            # Deployment та Service для PostgreSQL
│       │   ├── secret.yaml              # Чутливі змінні середовища (SECRET_KEY, POSTGRES_PASSWORD)
│       │   └── service.yaml             # Service типу LoadBalancer (AWS ELB)
│       ├── Chart.yaml                   # Метадані Helm-чарту застосунку
│       └── values.yaml                  # Конфігурація релізу (image.tag оновлюється через Jenkins)
├── modules/
│   ├── argo_cd/
│   │   ├── charts/
│   │   │   ├── templates/
│   │   │   │   ├── application.yaml     # Argo CD Application маніфест для GitOps
│   │   │   │   └── repository.yaml      # Декларативна реєстрація Git-репозиторію в Argo CD
│   │   │   ├── Chart.yaml
│   │   │   └── values.yaml
│   │   ├── argocd.tf                    # Розгортання Argo CD та чарту застосунків через Helm
│   │   ├── outputs.tf
│   │   ├── providers.tf
│   │   ├── values.yaml                  # Конфігурація Helm-релізу Argo CD
│   │   └── variables.tf
│   ├── ecr/
│   │   ├── ecr.tf                       # Приватний реєстр Amazon ECR
│   │   ├── outputs.tf
│   │   └── variables.tf
│   ├── eks/
│   │   ├── aws_ebs_csi_driver.tf        # Драйвер EBS CSI для динамічного створення томів (StorageClass gp3)
│   │   ├── eks.tf                       # Кластер Amazon EKS та Node Group
│   │   ├── jenkins_ecr_irsa.tf          # IAM Role for Service Account (IRSA) для доступу Jenkins до ECR
│   │   ├── outputs.tf
│   │   └── variables.tf
│   ├── jenkins/
│   │   ├── jenkins.tf                   # Розгортання Jenkins через Helm та Kubernetes Secret для GitHub
│   │   ├── outputs.tf
│   │   ├── providers.tf
│   │   ├── values.yaml                  # Конфігурація Jenkins (JCasC, Job DSL, Pod Templates)
│   │   └── variables.tf
│   ├── s3-backend/
│   │   ├── dynamodb.tf                  # Таблиця блокування стану Terraform
│   │   ├── outputs.tf
│   │   ├── s3.tf                        # S3-бакет для збереження Terraform state
│   │   └── variables.tf
│   └── vpc/
│       ├── outputs.tf
│       ├── routes.tf                    # Таблиці маршрутизації та NAT Gateway
│       ├── variables.tf
│       └── vpc.tf                       # VPC, публічні та приватні підмережі
├── .terraform.lock.hcl
├── backend.tf                           # Конфігурація віддаленого S3 backend
├── main.tf                              # Головний файл оркестрації Terraform-модулів
├── outputs.tf                           # Вихідні параметри інфраструктури
├── variables.tf                         # Вхідні змінні кореневого модуля (включно з чутливим токеном)
└── README.md                            # Документація проєкту
```

---

## Попередні вимоги

Перед початком роботи необхідно встановити та налаштувати:

| Інструмент | Вимоги                                            |
| ---------- | ------------------------------------------------- |
| AWS CLI    | Налаштований AWS-профіль                          |
| Terraform  | Версія >= 1.5                                     |
| kubectl    | Для керування Kubernetes                          |
| Helm       | Версія >= 3.12                                    |
| Git        | Для роботи з GitHub                               |
| Docker     | Для локальної роботи з Docker-образами за потреби |

### AWS Permissions

AWS IAM User або IAM Role повинні мати необхідні дозволи для роботи з:

- VPC та EC2.
- IAM та EKS.
- ECR.
- S3 та DynamoDB.
- EBS.
- Elastic Load Balancing.

### GitHub Credentials (JCasC)

Для автоматичного оновлення Helm-чарта Jenkins використовує GitHub Personal Access Token (Classic PAT із правом `repo`).

Токен передається під час розгортання через змінну середовища Terraform без збереження у відкритому коді:

```bash
export TF_VAR_github_token="<YOUR_GITHUB_PAT>"
```

Terraform створює Kubernetes Secret jenkins-github-secret, а плагін JCasC автоматично реєструє облікові дані github-creds та CI-пайплайн django-app-ci:

| Параметр | Значення                     |
| -------- | ---------------------------- |
| ID       | `github-creds`               |
| Type     | Username with password       |
| Username | GitHub username              |
| Password | GitHub Personal Access Token |

Для Classic Personal Access Token необхідний дозвіл `repo`, який дозволяє виконувати запис у відповідний репозиторій.

**Важливо:** токен не повинен зберігатися безпосередньо у `Jenkinsfile`, Terraform-файлах або відкритому GitHub-репозиторії.

---

# Етапи розгортання

## 1. Розгортання AWS Infrastructure через Terraform

Усі основні ресурси AWS створюються за допомогою Terraform.

### 1.1. Ініціалізація Terraform

Ініціалізуйте робочу директорію:

```bash
terraform init
```

Команда завантажує необхідні провайдери та модулі й ініціалізує Terraform Backend.

> Якщо S3-бакет і DynamoDB використовуються як Remote Backend, вони мають бути створені до виконання `terraform init`. Якщо ці ресурси також керуються Terraform, їх потрібно попередньо розгорнути окремим bootstrap-процесом.

### 1.2. Перевірка конфігурації

```bash
terraform validate
```

Перевіряємо план створення інфраструктури:

```bash
terraform plan
```

### 1.3. Розгортання інфраструктури

```bash
terraform apply
```

Підтвердіть виконання змін після перевірки плану.

Terraform створює:

- VPC та підмережі.
- Internet Gateway та NAT Gateway.
- Amazon ECR Repository.
- Amazon EKS Cluster.
- Managed Node Group.
- IAM Roles та IRSA (`jenkins_ecr_role_arn` передається динамічно в Helm values Jenkins).
- EBS CSI Driver (`gp3`).
- Jenkins через Helm (із JCasC та Job DSL).
- Argo CD та декларативні ресурси `Repository` і `Application` через Helm.

### 1.4. Перевірка створених ресурсів

```bash
terraform output
```

Перевіряємо ресурси AWS:

```bash
aws eks list-clusters --region us-west-2
```

Перевіряємо репозиторії ECR:

```bash
aws ecr describe-repositories --region us-west-2
```

---

## 2. Підключення до Kubernetes-кластера

Оновлюємо локальну конфігурацію `kubectl`:

```bash
aws eks update-kubeconfig \
  --region us-west-2 \
  --name <EKS_CLUSTER_NAME>
```

Перевіряємо робочі вузли:

```bash
kubectl get nodes
```

Очікуваний результат - робочі вузли перебувають у статусі `Ready`.

Перевіряємо Kubernetes Namespaces:

```bash
kubectl get namespaces
```

Перевіряємо системні компоненти:

```bash
kubectl get pods -n kube-system
```

---

## 3. Налаштування Jenkins CI Pipeline

Jenkins автоматично встановлюється в Kubernetes за допомогою Terraform та Helm.
github-creds і django-app-ci створюються декларативно через JCasC + Job DSL без ручних кроків у UI.

Для виконання CI-процесів використовується Kubernetes Agent із двома контейнерами:

- `kaniko` - збирання та публікація Docker-образу.
- `git` - отримання вихідного коду та оновлення GitHub-репозиторію.

### 3.1. Архітектура Jenkins Agent

```text
          [ Jenkins Controller ]
                    |
                    | Create Agent Pod
                    v
             [ Kubernetes Pod ]
                    |
             +------+------+
             |             |
             v             v
          [Kaniko]       [Git]
             |             |
             v             v
        [Build Image]  [Update values.yaml]
             |             |
             v             v
         [Amazon ECR]   [GitHub Push]
```

### 3.2. Перевірка Jenkins

Отримуємо список подів Jenkins:

```bash
kubectl get pods -n jenkins
```

Перевіряємо сервіси:

```bash
kubectl get svc -n jenkins
```

Переглядаємо логи Jenkins:

```bash
kubectl logs -n jenkins deployment/jenkins
```

Для отримання доступу до вебінтерфейсу Jenkins можна використати port-forward, якщо сервіс налаштований як ClusterIP:

```bash
kubectl port-forward svc/jenkins 8080:8080 -n jenkins
```

Після цього відкрийте у браузері:

```text
http://localhost:8080
```

### 3.3. Налаштування Jenkins Pipeline

Pipeline job django-app-ci створюється автоматично через Job DSL.

Pipeline складається з двох основних стадій.

**Stage 1 - Build and Push Docker Image**

Kaniko виконує:

1. Отримання Dockerfile та вихідного коду Django.
2. Збирання Docker-образу.
3. Присвоєння тегів `${BUILD_NUMBER}`.
4. Завантаження образу до Amazon ECR.

Приклад тегування:

```text
django-app:8
```

**Stage 2 - Update Helm Chart Tag**

Git-контейнер виконує:

1. Отримання актуального стану GitHub-репозиторію.
2. Перемикання на гілку `lesson-8-9`.
3. Оновлення параметра `image.tag` у `charts/django-app/values.yaml`.
4. Створення автоматичного коміту.
5. Відправлення змін до GitHub.

Приклад коміту:

```text
chore(ci): update image tag to 8
```

Передача облікових даних у sh виконується через одинарні лапки (sh '''...''').
Після цього GitHub містить актуальний тег Docker-образу, який повинен використовувати Argo CD.

### 3.4. Перевірка результату Jenkins

У Jenkins відкрийте відповідний Pipeline Job.

Перевірте:

- Наявність успішного Build.
- Успішне виконання `Build and Push Docker Image`.
- Успішне виконання `Update Helm Chart Tag`.
- Відсутність помилок під час Git Push.

Перевірити завантажені Docker-образи можна через AWS CLI:

```bash
aws ecr describe-images \
  --repository-name django-app \
  --region us-west-2
```

---

## 4. Налаштування GitOps через Argo CD

Argo CD автоматично встановлюється в Kubernetes за допомогою Terraform та Helm.

Його основне завдання - постійно порівнювати конфігурацію в GitHub із фактичним станом Kubernetes-кластера.

### 4.1. Перевірка Argo CD

Перевіряємо поди:

```bash
kubectl get pods -n argocd
```

Перевіряємо сервіси:

```bash
kubectl get svc -n argocd
```

### 4.2. Доступ до вебінтерфейсу Argo CD

Для локального доступу можна використати port-forward:

```bash
kubectl port-forward svc/argocd-server 8081:443 -n argocd
```

Відкриваємо у браузері:

```text
https://localhost:8081
```

Для початкового отримання адміністративного пароля:

```bash
kubectl get secret argocd-initial-admin-secret \
  -n argocd \
  -o jsonpath="{.data.password}" | base64 -d
```

> Після першого входу рекомендується змінити початковий пароль адміністратора.
> Доступ іде по HTTPS (без прапорця --insecure), а команду отримання пароля можна взяти з terraform output argocd_password_cmd

### 4.3. Налаштування Argo CD Application

Для GitOps створюється об'єкт `Application`, який відстежує Helm-чарт Django-застосунку в GitHub.

Основні параметри:

| Параметр          | Значення                                |
| ----------------- | --------------------------------------- |
| Application       | `django-app`                            |
| Source Repository | GitHub Repository                       |
| Target Revision   | `lesson-8-9`                            |
| Path              | `lesson-8-9/charts/django-app`          |
| Destination       | Kubernetes Cluster                      |
| Namespace         | `default`                               |
| Sync Policy       | Automated (prune: true, selfHeal: true) |

Автоматична синхронізація дозволяє Argo CD самостійно застосовувати зміни після оновлення Git-репозиторію.

> Чарт modules/argo_cd/charts декларативно створює два ресурси: Repository (templates/repository.yaml) та Application (templates/application.yaml).

### 4.4. Принцип роботи автоматичної синхронізації

```text
[Jenkins]
    |
    | Update image.tag
    v
[GitHub: values.yaml]
    |
    | Detect Git Changes
    v
[Argo CD]
    |
    | Compare Desired State
    v
[Kubernetes]
    |
    | Apply Helm Changes
    v
[Django Deployment]
    |
    | Rolling Update
    v
[New Application Version]
```

Argo CD використовує Git як єдине джерело бажаного стану інфраструктури та застосунку.

Таким чином, Jenkins відповідає за CI та оновлення конфігурації, а Argo CD - за CD та синхронізацію Kubernetes.

### 4.5. Перевірка Argo CD

Перевіряємо створені Application:

```bash
kubectl get applications -n argocd
```

Або за допомогою Argo CD CLI:

```bash
argocd app list
```

Перевіряємо стан конкретного застосунку:

```bash
argocd app get django-app
```

Очікувані статуси:

- `Synced` - конфігурація Kubernetes відповідає конфігурації Git.
- `Healthy` - ресурси застосунку перебувають у справному стані.

---

## 5. Автоматичне масштабування Django за допомогою HPA

Для автоматичного горизонтального масштабування застосунку використовується Kubernetes Horizontal Pod Autoscaler.

Параметри HPA:

| Параметр                     | Значення |
| ---------------------------- | -------- |
| Мінімальна кількість реплік  | 1        |
| Максимальна кількість реплік | 6        |
| Метрика                      | CPU      |
| Цільове завантаження CPU     | 70%      |

Metrics Server забезпечує отримання метрик, необхідних для роботи HPA.

Перевіряємо HPA:

```bash
kubectl get hpa
```

Переглядаємо детальну інформацію:

```bash
kubectl describe hpa django-app-hpa
```

Перевіряємо метрики:

```bash
kubectl top pods
```

HPA автоматично збільшує або зменшує кількість реплік Django відповідно до поточного навантаження.

---

## 6. Перевірка працездатності застосунку

### 6.1. Перевірка Kubernetes-ресурсів

```bash
kubectl get all
```

Перевірка Deployment:

```bash
kubectl get deployments
```

Перевірка Pod:

```bash
kubectl get pods
```

Перевірка Service:

```bash
kubectl get services
```

### 6.2. Перевірка PostgreSQL

```bash
kubectl get pods -l app=db
```

Перевірка сервісу бази даних:

```bash
kubectl get svc db
```

Перевірка секрету:

```bash
kubectl get secret django-app-secret
```

### 6.3. Перевірка зовнішнього доступу

Отримуємо зовнішню адресу LoadBalancer:

```bash
kubectl get svc django-app
```

Виконуємо HTTP-запит:

```bash
curl -I http://<LOAD_BALANCER_ADDRESS>
```

Очікувана відповідь залежить від конфігурації Django:

```text
HTTP/1.1 200 OK
```

Також можливі коректні відповіді перенаправлення `301` або `302`.

Після успішного розгортання застосунок доступний через зовнішню адресу AWS LoadBalancer.

---

## Результат автоматизованого CI/CD

Після завершення налаштування весь процес оновлення застосунку відбувається автоматично:

| Етап | Компонент     | Результат                           |
| ---- | ------------- | ----------------------------------- |
| 1    | GitHub        | Отримання змін вихідного коду       |
| 2    | Jenkins       | Запуск CI Pipeline                  |
| 3    | Kaniko        | Збирання Docker-образу              |
| 4    | Amazon ECR    | Збереження нового образу            |
| 5    | Jenkins + Git | Оновлення `image.tag` у Helm values |
| 6    | GitHub        | Збереження нового коміту            |
| 7    | Argo CD       | Виявлення змін у Git                |
| 8    | Helm          | Оновлення Kubernetes-ресурсів       |
| 9    | Kubernetes    | Rolling Update Django Deployment    |
| 10   | HPA           | Автоматичне масштабування подів     |

**Результат:** реалізовано автоматизований процес доставки нових версій Django-застосунку до Amazon EKS із використанням GitOps.

---

## Вирішені технічні проблеми

Під час налаштування інфраструктури та CI/CD були виявлені й усунені такі проблеми.

### 1. Конфлікт імен гілки та директорії Git

**Проблема:**

Команда:

```bash
git checkout lesson-8-9
```

завершувалася помилкою `exit code 128`, оскільки в корені репозиторію існувала директорія з такою самою назвою, як і Git-гілка.

**Рішення:**

Використано явне перемикання на віддалену гілку:

```bash
git checkout -B ${GIT_BRANCH} origin/${GIT_BRANCH}
```

Також налаштовано безпечну робочу директорію Git та збережено `Jenkinsfile` у кодуванні UTF-8 без BOM.

### 2. Помилка GitHub Push (HTTP 403)

**Проблема:**

Jenkins не мав достатніх дозволів для запису змін у GitHub-репозиторій.

**Рішення:**

- Створено GitHub Personal Access Token із дозволом `repo`.
- Передано облікові дані у Jenkins декларативно через Kubernetes Secret (`jenkins-github-secret`) та JCasC (`github-creds`).
- Перевірено можливість виконання Git Push із Jenkins.

### 3. Статус Degraded у Argo CD для HPA

**Проблема:**

HorizontalPodAutoscaler не міг отримати метрики CPU:

```text
unable to get metrics for resource cpu
```

Через відсутність метрик Argo CD відображав некоректний стан HPA.

**Рішення:**

Розгорнуто Kubernetes Metrics Server:

```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

Після встановлення Metrics Server HPA отримав доступ до необхідних метрик, а стан застосунку в Argo CD змінився на:

```text
Healthy / Synced
```

---

## Очищення ресурсів AWS (Cleanup)

Після завершення тестування та фіксації результатів інфраструктуру було видалено для уникнення подальших витрат AWS.

### 1. Видалення Kubernetes-застосунків

Перед видаленням інфраструктури необхідно видалити GitOps-застосунок та ресурси, створені ним:

```bash
argocd app delete django-app
```

Перевіряємо сервіси Kubernetes:

```bash
kubectl get services --all-namespaces
```

Це дозволяє переконатися, що сервіси типу LoadBalancer видалені та AWS Load Balancer звільнений.

### 2. Видалення Terraform-інфраструктури

Перевірте план видалення:

```bash
terraform plan -destroy
```

Видаліть ресурси:

```bash
terraform destroy
```

Ця операція видаляє ресурси, якими керує Terraform, зокрема:

- Amazon EKS Cluster.
- EC2 Worker Nodes.
- VPC та підмережі.
- NAT Gateway.
- Internet Gateway.
- Amazon ECR Repository.
- Jenkins.
- Argo CD.
- Інші ресурси, визначені конфігурацією Terraform.

### 3. Перевірка видалення ресурсів

Перевіряємо активні EC2-інстанси:

```bash
aws ec2 describe-instances \
  --region us-west-2 \
  --filters Name=instance-state-name,Values=running
```

Перевіряємо EKS-кластери:

```bash
aws eks list-clusters --region us-west-2
```

Перевіряємо ECR-репозиторії:

```bash
aws ecr describe-repositories --region us-west-2
```

Перевіряємо балансувальники:

```bash
aws elb describe-load-balancers --region us-west-2
```

Перевіряємо Elastic IP:

```bash
aws ec2 describe-addresses --region us-west-2
```

Перевіряємо томи EBS:

```bash
aws ec2 describe-volumes --region us-west-2
```

Окремо перевіряємо залишкові EBS-томи та інші ресурси, які можуть продовжувати генерувати витрати.

**Результат:** після завершення очищення активні ресурси проєкту в регіоні `us-west-2` відсутні.

> Примітка: Remote State S3 та DynamoDB можуть залишатися окремими ресурсами. Їх потрібно видаляти лише після резервного копіювання та завершення роботи з Terraform State.

---

## Висновки

У межах цього проєкту реалізовано повний автоматизований CI/CD та GitOps-процес розгортання Django-застосунку в Amazon EKS.

Під час виконання завдання було опрацьовано такі практичні аспекти:

- Автоматизація створення AWS-інфраструктури за допомогою Terraform.
- Модульна організація Infrastructure as Code.
- Розгортання Jenkins та Argo CD через Helm.
- Використання Kubernetes Agents для виконання CI-процесів.
- Бездемонне збирання Docker-образів за допомогою Kaniko.
- Автоматична публікація Docker-образів в Amazon ECR.
- Інтеграція Jenkins із GitHub через Personal Access Token.
- Автоматичне оновлення Helm-конфігурації.
- Реалізація GitOps за допомогою Argo CD.
- Автоматична синхронізація Kubernetes із GitHub.
- Горизонтальне масштабування застосунку через HPA.
- Діагностика та усунення проблем інтеграції CI/CD-компонентів.

**Підсумок:** створено автоматизований конвеєр доставки програмного забезпечення, у якому Jenkins відповідає за збирання та публікацію Docker-образів, а Argo CD забезпечує декларативне розгортання та синхронізацію застосунку в Kubernetes.

---

**Навчальний проєкт:** Lesson 8–9 - Jenkins, Terraform, Helm та Argo CD.

**Хмарна платформа:** Amazon Web Services (`us-west-2`).

**Методологія:** Infrastructure as Code (IaC), Continuous Integration (CI), Continuous Delivery (CD), GitOps.
