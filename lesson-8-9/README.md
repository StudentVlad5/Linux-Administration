# Домашнє завдання: Розгортання застосунку в AWS EKS за допомогою Terraform та Helm - Lesson 7

## Опис проєкту

Цей проєкт демонструє автоматизоване розгортання хмарної інфраструктури **Amazon Web Services (AWS)** за допомогою **Terraform** та подальше розгортання вебзастосунку в **Amazon Elastic Kubernetes Service (EKS)** за допомогою **Helm**.

Інфраструктура створюється з використанням модульної архітектури Terraform із віддаленим збереженням стану в Amazon S3 та блокуванням паралельного доступу через DynamoDB.

Проєкт передбачає розгортання вебзастосунку **Django** та бази даних **PostgreSQL** усередині Kubernetes-кластера, забезпечуючи зовнішній доступ через AWS Load Balancer та автоматичне горизонтальне масштабування за допомогою Kubernetes Horizontal Pod Autoscaler (HPA).

### Використані технології

| Технологія | Призначення                             |
| ---------- | --------------------------------------- |
| AWS        | Хмарна інфраструктура                   |
| Terraform  | Інфраструктура як код (IaC)             |
| Amazon VPC | Ізоляція та налаштування мережі         |
| Amazon S3  | Віддалене збереження стану Terraform    |
| DynamoDB   | Блокування стану Terraform              |
| Amazon ECR | Реєстр Docker-образів                   |
| Amazon EKS | Керований Kubernetes-кластер            |
| Docker     | Контейнеризація застосунку              |
| Kubernetes | Оркестрація контейнерів                 |
| Helm       | Розгортання застосунку в Kubernetes     |
| Django     | Фреймворк вебзастосунку                 |
| PostgreSQL | Реляційна база даних                    |
| HPA        | Горизонтальне автоматичне масштабування |
| kubectl    | Керування Kubernetes-кластером          |

---

## Структура проєкту

```text
lesson-7/
│
├── main.tf
├── backend.tf
├── outputs.tf
│
├── modules/
│   ├── s3-backend/
│   │   ├── s3.tf
│   │   ├── dynamodb.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   ├── vpc/
│   │   ├── vpc.tf
│   │   ├── routes.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   ├── ecr/
│   │   ├── ecr.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   └── eks/
│       ├── eks.tf
│       ├── variables.tf
│       └── outputs.tf
│
├── charts/
│   └── django-app/
│       ├── Chart.yaml
│       ├── values.yaml
│       └── templates/
│           ├── configmap.yaml
│           ├── deployment.yaml
│           ├── postgres.yaml
│           ├── service.yaml
│           └── hpa.yaml
│
└── README.md
```

---

## Архітектура проєкту

Інфраструктура складається з чотирьох основних модулів Terraform та одного Helm-чарта.

### 1. Інфраструктура Terraform

#### S3 Backend (`modules/s3-backend/`)

Створює ресурси для віддаленого збереження стану Terraform:

- Приватний S3-бакет для збереження `terraform.tfstate`.
- Увімкнене версіювання об'єктів S3.
- Шифрування даних.
- Таблиця DynamoDB для блокування стану за допомогою `LockID`.

#### VPC (`modules/vpc/`)

Створює ізольовану віртуальну мережу в AWS:

- VPC із CIDR-блоком `10.0.0.0/16`.
- Публічні та приватні підмережі в декількох Availability Zones.
- Internet Gateway (IGW).
- NAT Gateway.
- Таблиці маршрутизації та мережеві маршрути.
- Теги підмереж для інтеграції з Kubernetes.

Регіон AWS: `us-west-2`.

#### ECR (`modules/ecr/`)

Створює приватний репозиторій Amazon Elastic Container Registry:

- Назва репозиторію: `django-app`.
- Автоматичне сканування Docker-образів на вразливості під час завантаження.
- Збереження та розповсюдження Docker-образів.

#### EKS (`modules/eks/`)

Створює керований Kubernetes-кластер:

- Amazon EKS Control Plane.
- IAM-ролі та необхідні дозволи.
- Managed Node Group.
- Робочі вузли на базі інстансів `t3.micro`.
- Розміщення робочих вузлів у приватних підмережах.

### 2. Kubernetes-застосунок (Helm)

Helm-чарт розташований у директорії `charts/django-app/`.

| Файл              | Призначення                                                     |
| ----------------- | --------------------------------------------------------------- |
| `configmap.yaml`  | Централізоване зберігання конфігурації застосунку та бази даних |
| `deployment.yaml` | Deployment вебзастосунку Django                                 |
| `postgres.yaml`   | Deployment PostgreSQL та внутрішній сервіс ClusterIP            |
| `service.yaml`    | Зовнішній сервіс типу LoadBalancer                              |
| `hpa.yaml`        | Horizontal Pod Autoscaler для автоматичного масштабування       |

**Основні параметри застосунку:**

- Django працює на порту `8000`.
- Версія PostgreSQL: `15-alpine`.
- Внутрішній сервіс бази даних: `db`.
- Зовнішній HTTP-доступ через AWS Load Balancer на порту `80`.
- Цільовий рівень використання CPU для HPA: `70%`.

---

## Попередні вимоги

Перед розгортанням інфраструктури необхідно встановити та налаштувати такі інструменти:

| Інструмент     | Вимоги                             |
| -------------- | ---------------------------------- |
| AWS CLI        | Налаштований через `aws configure` |
| Terraform      | Версія >= 1.5                      |
| Docker Desktop | Запущений Docker daemon            |
| kubectl        | Встановлений                       |
| Helm           | Версія >= 3.12                     |

### Необхідні дозволи AWS

Користувач або IAM-роль AWS повинні мати дозволи на керування такими сервісами:

- VPC та EC2.
- IAM.
- S3.
- DynamoDB.
- ECR.
- EKS.

---

## Інструкція з розгортання

### Етап 1. Ініціалізація Terraform

Ініціалізуємо робочу директорію Terraform:

```bash
terraform init
```

Команда завантажує необхідні провайдери, ініціалізує модулі та налаштовує Terraform Backend.

> **Примітка:** Якщо S3-бакет і таблиця DynamoDB створюються цим проєктом, їх необхідно попередньо створити до виконання `terraform init`, якщо вони вже вказані в `backend.tf`. Terraform Backend ініціалізується до того, як Terraform зможе створити ресурси через модулі.

### Етап 2. Перевірка плану розгортання

```bash
terraform plan
```

Команда формує план змін і показує, які ресурси AWS будуть створені, оновлені або видалені.

### Етап 3. Розгортання інфраструктури AWS

```bash
terraform apply
```

Перевіряємо план виконання та підтверджуємо розгортання.

Terraform створює:

- VPC та мережеву інфраструктуру.
- Репозиторій Amazon ECR.
- Кластер Amazon EKS.
- Керовану групу робочих вузлів Kubernetes.

Після завершення Terraform виводить URL репозиторію ECR та назву кластера EKS.

### Етап 4. Підключення до Kubernetes-кластера

Оновлюємо локальну конфігурацію `kubectl`:

```bash
aws eks update-kubeconfig \
  --region us-west-2 \
  --name <EKS_CLUSTER_NAME>
```

Перевіряємо стан робочих вузлів:

```bash
kubectl get nodes
```

Очікуваний результат: робочі вузли повинні перейти в стан `Ready`.

### Етап 5. Встановлення Metrics Server

Metrics Server необхідний для роботи HPA, оскільки забезпечує збір метрик використання CPU та пам'яті.

```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

Перевіряємо стан розгортання:

```bash
kubectl get deployment metrics-server -n kube-system
```

### Етап 6. Оптимізація CoreDNS

Зменшуємо кількість реплік CoreDNS до однієї, щоб зменшити споживання ресурсів кластера:

```bash
kubectl scale deployment coredns \
  -n kube-system \
  --replicas=1
```

Це налаштування призначене для економії ресурсів обмежених за потужністю робочих вузлів `t3.micro`.

---

## Збірка Docker-образу та завантаження в ECR

### Етап 1. Авторизація Docker у Amazon ECR

Замість `<ACCOUNT_ID>` вкажіть ідентифікатор свого AWS-акаунта.

```bash
aws ecr get-login-password --region us-west-2 | \
docker login \
  --username AWS \
  --password-stdin <ACCOUNT_ID>.dkr.ecr.us-west-2.amazonaws.com
```

### Етап 2. Збірка Docker-образу

Виконуємо команду в директорії, де розташований `Dockerfile`:

```bash
docker build -t django-app .
```

### Етап 3. Присвоєння тегу Docker-образу

```bash
docker tag django-app:latest \
  <ACCOUNT_ID>.dkr.ecr.us-west-2.amazonaws.com/django-app:latest
```

### Етап 4. Завантаження образу в ECR

```bash
docker push \
  <ACCOUNT_ID>.dkr.ecr.us-west-2.amazonaws.com/django-app:latest
```

Після виконання команди Docker-образ буде доступний у приватному репозиторії Amazon ECR, звідки його зможуть отримувати робочі вузли EKS.

---

## Розгортання застосунку за допомогою Helm

### Етап 1. Перевірка Helm-шаблонів

Перед встановленням застосунку виконуємо локальну перевірку Helm-шаблонів:

```bash
helm template django-release ./charts/django-app
```

Команда генерує Kubernetes-маніфести з використанням параметрів, визначених у `values.yaml`.

### Етап 2. Встановлення Helm-релізу

```bash
helm install django-release ./charts/django-app
```

Команда створює такі ресурси Kubernetes:

- ConfigMap.
- Django Deployment.
- PostgreSQL Deployment.
- PostgreSQL ClusterIP Service.
- Зовнішній LoadBalancer Service.
- Horizontal Pod Autoscaler.

### Етап 3. Оновлення Helm-релізу

Якщо конфігурація Helm-чарта змінилася, застосовуємо оновлення:

```bash
helm upgrade django-release ./charts/django-app
```

### Етап 4. Виконання міграцій Django

Міграції бази даних необхідно виконати всередині запущеного контейнера Django.

**Linux / macOS / Git Bash:**

```bash
POD=$(kubectl get pods -l app=django-app \
  -o jsonpath="{.items[0].metadata.name}")

kubectl exec -it $POD -- python manage.py migrate
```

**Windows PowerShell:**

```powershell
$POD = kubectl get pods -l app=django-app -o jsonpath="{.items[0].metadata.name}"

kubectl exec -it $POD -- python manage.py migrate
```

Команда створює необхідні таблиці бази даних та застосовує всі очікувані міграції Django.

---

## Перевірка працездатності

### 1. Перевірка ресурсів Kubernetes

Отримуємо список усіх основних ресурсів:

```bash
kubectl get all
```

Перевіряємо HPA:

```bash
kubectl get hpa
```

Перевіряємо Helm-релізи:

```bash
helm list
```

**Очікуваний результат:**

- Поди Django перебувають у статусі `Running`.
- Под PostgreSQL перебуває у статусі `Running`.
- Сервіс LoadBalancer отримав зовнішню DNS-адресу.
- HPA відображає поточний рівень використання CPU.
- Helm-реліз має статус `deployed`.

### 2. Перевірка мережевих Endpoints

```bash
kubectl get endpoints django-release-service
```

Очікуваний результат: у списку Endpoints відображається внутрішня IP-адреса пода Django та порт `8000`.

### 3. Перевірка зовнішнього доступу до застосунку

Отримуємо зовнішню адресу LoadBalancer:

```bash
kubectl get services
```

Виконуємо HTTP-запит:

```bash
curl -I http://<LOAD_BALANCER_ADDRESS>
```

**Очікувана відповідь:**

```text
HTTP/1.1 200 OK
```

Також можуть бути коректними відповіді перенаправлення `301` або `302`, залежно від конфігурації Django.

Після успішного виконання всіх етапів вебзастосунок повинен бути доступний через зовнішню адресу LoadBalancer.

---

## Підсумкова конфігурація

| Компонент                 | Конфігурація     |
| ------------------------- | ---------------- |
| Регіон AWS                | `us-west-2`      |
| CIDR VPC                  | `10.0.0.0/16`    |
| Реєстр контейнерів        | Amazon ECR       |
| Kubernetes-кластер        | Amazon EKS       |
| Тип інстансів             | `t3.micro`       |
| Вебзастосунок             | Django           |
| Порт застосунку           | `8000`           |
| База даних                | PostgreSQL 15    |
| Сервіс бази даних         | ClusterIP (`db`) |
| Зовнішній сервіс          | LoadBalancer     |
| Автомасштабування         | Kubernetes HPA   |
| Цільове використання CPU  | `70%`            |
| Керування інфраструктурою | Terraform        |
| Розгортання застосунку    | Helm             |

---

## Видалення інфраструктури

Щоб уникнути зайвих витрат AWS, після завершення роботи необхідно видалити створені ресурси.

Видаляємо Helm-реліз:

```bash
helm uninstall django-release
```

Видаляємо інфраструктуру, керовану Terraform:

```bash
terraform destroy
```

> **Увага!** Перед видаленням перевірте залежності ресурсів Terraform. S3-бакет із файлом стану та таблиця DynamoDB можуть потребувати окремого керування. Не видаляйте S3-бакет із Terraform State до створення резервної копії стану.

---

## Додаткові примітки

- Замініть усі шаблонні значення, наприклад `<ACCOUNT_ID>` та `<EKS_CLUSTER_NAME>`, на відповідні значення вашого AWS-акаунта.
- Переконайтеся, що тег Docker-образу в `values.yaml` відповідає образу, завантаженому в ECR.
- Перед розгортанням налаштуйте змінні середовища Django та облікові дані для підключення до PostgreSQL.
- Не зберігайте конфіденційні дані, паролі та production `SECRET_KEY` у відкритих GitHub-репозиторіях.
- Переконайтеся, що мережеві налаштування AWS та IAM-дозволи налаштовані правильно.
- Для production-середовищ рекомендується використовувати постійне сховище даних PostgreSQL та окремий сервіс керування секретами.

---

**Проєкт:** Lesson 7 — Розгортання AWS EKS за допомогою Terraform та Helm.

**Мета:** Автоматизація хмарної інфраструктури та розгортання контейнеризованого застосунку в Kubernetes.
