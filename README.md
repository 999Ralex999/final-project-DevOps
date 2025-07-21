# 📦 Проєкт: фінальний проєкт

## 🧩 Тема: Моніторинг Prometheus + Grafana в Kubernetes-кластері

Цей проєкт демонструє розгортання системи моніторингу в Kubernetes-кластері з використанням Helm-чартів **Prometheus** та **Grafana**.

Моніторинг реалізовано у headless-режимі (без браузера), повністю через CLI: `helm`, `kubectl`, `curl`, `w3m`.

Prometheus збирає метрики з кластеру, Grafana візуалізує їх з підключеним Data Source. Дашборд передано через Helm-чарт, хоча API `/api/search` не повертає його у списку — це обмеження стандартного механізму імпорту.

---

## 📂 Структура проєкту

- `main.tf`, `variables.tf`, `outputs.tf` — основні конфігураційні файли Terraform  
- `terraform.tfvars`, `.terraform.lock.hcl` — збереження стану та змінних  
- `modules/` — модулі інфраструктури:
  - `vpc/` — VPC з сабнетами
  - `s3-backend/` — S3 бакет і DynamoDB для бекенду
  - `rds/` — модуль для бази даних Aurora/RDS
  - `ecr/`, `jenkins/`, `argocd/` — контейнери, CI та CD  
- `django-app/` — вихідний код Django застосунку  
- `django-chart/` — Helm-чарт для Django застосунку  
- `grafana/` — дашборд і `grafana-values.yaml`  
- `helm/app/` — додаткові Helm-шаблони  
- `Jenkinsfile` — пайплайн CI (build, push, update Helm)  
- `aws-auth.yaml` — конфіг для доступу до EKS  
- `tfplan` — збережений план застосування

---

## 🛠️ Використані технології

- **Terraform** — для управління інфраструктурою AWS (VPC, EKS, S3, RDS, ECR)
- **Helm** — шаблонізація і встановлення Prometheus та Grafana в кластері Kubernetes
- **Kubernetes** — оркестрація застосунків і сервісів
- **Prometheus** — збір метрик з кластеру Kubernetes (kube-state-metrics, node-exporter, pushgateway)
- **Grafana** — візуалізація метрик і створення дашбордів
- **Jenkins** — CI для побудови Docker-образу та оновлення Helm-чарту
- **Argo CD** — GitOps-деплой у кластері
- **AWS ECR** — зберігання Docker-образів
- **AWS S3 + DynamoDB** — зберігання стейтів Terraform

---

## ✅ Що реалізовано

- Розгорнуто **систему моніторингу** в Kubernetes:
  - Установлено Prometheus через Helm-чарт (`prometheus-community/prometheus`)
  - Установлено Grafana через Helm-чарт (`grafana/grafana`)
  - Обидва сервіси працюють у namespace `monitoring`
- Підключено **Prometheus як Data Source** у Grafana через `datasources.yaml`
- Створено **кастомний дашборд** у форматі JSON (`up-dashboard.json`)
  - Додано до Grafana через `values.yaml` → `dashboards.default`
  - API `/api/search` не відображає його, що є відомим обмеженням headless-режиму
- Встановлено **Node Exporter**, **PushGateway**, **Kube State Metrics**
- Виконано повну CLI-інтеграцію:
  - без GUI: доступ через `kubectl port-forward` та `curl`
  - перевірка метрик: `http://localhost:9090/api/v1/targets`
  - перевірка дашборду: `kubectl exec + /api/search`
- Перевірено, що Prometheus збирає метрики з кластеру (успішні targets)

---

## 🧪 Як застосувати Helm-чарти та перевірити

> ⚙️ Передумови:
> - Підключений кластер EKS
> - `kubectl` та `helm` встановлені
> - Виконано `terraform apply` для створення інфраструктури

### 1. Додати репозиторії Helm
```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
```

### 2. Встановити Prometheus
```bash
kubectl create namespace monitoring
helm install prometheus prometheus-community/prometheus \
  --namespace monitoring \
  --set server.persistentVolume.enabled=false
```

### 3. Встановити Grafana
```bash
helm install grafana grafana/grafana \
  --namespace monitoring \
  --values grafana/grafana-values.yaml
```

### 4. Перевірити статус pod'ів
```bash
kubectl get pods -n monitoring
```

### 5. Проброс портів для CLI-доступу

# В одному терміналі
```bash
kubectl port-forward -n monitoring svc/prometheus-server 9090:80
```
```bash
# В іншому терміналі
kubectl port-forward -n monitoring svc/grafana 3000:80
```

### 6. Перевірити метрики Prometheus
```bash
curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | {instance, health}'
```

### 7. Перевірити Data Source і дашборди Grafana
```bash
kubectl get pods -n monitoring -l app.kubernetes.io/name=grafana

kubectl exec -n monitoring <grafana-pod-name> -- \
  curl -s -u admin:admin123 http://localhost:3000/api/datasources

kubectl exec -n monitoring <grafana-pod-name> -- \
  curl -s -u admin:admin123 http://localhost:3000/api/search
```

---

## 📘 Особливості / висновки

- Успішно реалізовано повноцінну систему моніторингу Kubernetes-кластеру з використанням Prometheus і Grafana.
- Усі компоненти встановлено через Helm, без використання PVC (ефемерне зберігання, зручне для тестових середовищ).
- Доступ до Prometheus і Grafana організовано через `kubectl port-forward`, без відкриття сервісів у зовнішню мережу.
- Візуалізація метрик Grafana працює з підключеним Data Source (Prometheus), що підтверджується через API.
- Кастомний дашборд `up-dashboard.json` передано у Grafana через Helm, але не відображається в API `/api/search` — це відома особливість headless-деплою.
- Метрики збираються з kube-state-metrics, node-exporter, pushgateway — підтверджено через `/api/v1/targets`.

> 🔍 Проєкт повністю реалізовано у CLI-режимі без GUI, що відповідає інженерному підходу DevOps.

---

## ✅ Результат

- 📡 **Prometheus працює:** збирає метрики з Kubernetes-кластеру
- 📊 **Grafana доступна:** підключено Prometheus як Data Source
- 📈 **Дашборд up-dashboard передано через Helm:** візуалізація метрик через файл `.json`
- 🔐 **Доступ лише через port-forward:** без відкритих портів назовні
- ⚙️ **Всі Helm-релізи в статусі deployed:**
  - `prometheus`: prometheus-27.28.0
  - `grafana`: grafana-9.2.10

### 🔎 Outputs (опціонально)
> Виводи перевірені через CLI:

```bash
kubectl get pods -n monitoring
kubectl get svc -n monitoring
helm list -n monitoring
curl -s http://localhost:9090/api/v1/targets
```

---

## 👨‍💻 Автор

**Олександр Ребенок**

GitHub: [999Ralex999](https://github.com/999Ralex999)
