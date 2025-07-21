variable "ecr_name" {
  description = "Назва репозиторію ECR"
  type        = string
}

variable "scan_on_push" {
  description = "Чи вмикати автоматичне сканування Docker-образів під час завантаження"
  type        = bool
}
