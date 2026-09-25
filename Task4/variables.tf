variable "yc_token" {
  description = "OAuth/IAM-токен для доступа к Yandex Cloud"
  type        = string
  sensitive   = true
}

variable "cloud_id" {
  description = "Идентификатор облака Yandex Cloud"
  type        = string
}

variable "folder_id" {
  description = "Идентификатор каталога Yandex Cloud"
  type        = string
}

variable "zone" {
  description = "Зона доступности для развёртывания ресурсов"
  type        = string
  default     = "ru-central1-a"
}

variable "region_id" {
  description = "Регион для региональных ресурсов (например, балансировщика)"
  type        = string
  default     = "ru-central1"
}

variable "network_name" {
  description = "Базовое имя VPC-сети и производных ресурсов"
  type        = string
  default     = "future20-network"
}

variable "public_subnet_cidr" {
  description = "CIDR публичной подсети (портал, VPN-шлюз)"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR приватной подсети (доменные сервисы, ClickHouse)"
  type        = string
  default     = "10.0.2.0/24"
}

variable "admin_cidr" {
  description = "CIDR, с которого разрешён SSH-доступ для администрирования"
  type        = string
}

variable "vm_image_id" {
  description = "Идентификатор образа ОС для виртуальных машин"
  type        = string
}

variable "ssh_public_key_path" {
  description = "Путь к публичному SSH-ключу для доступа к VM"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "domain_vms" {
  description = "Виртуальные машины доменных сервисов (кроме ETL — у него отдельный ресурс из-за диска стейджинга)"
  type = map(object({
    description = string
    cores       = number
    memory      = number
    disk_size   = number
    subnet      = string # "public" или "private"
  }))
  default = {
    portal = {
      description = "Портал самообслуживания"
      cores       = 2
      memory      = 4
      disk_size   = 20
      subnet      = "public"
    }
    bus = {
      description = "Доменная шина событий / API-шлюз"
      cores       = 2
      memory      = 4
      disk_size   = 20
      subnet      = "private"
    }
    fintech = {
      description = "Домен «Финтех»"
      cores       = 2
      memory      = 4
      disk_size   = 20
      subnet      = "private"
    }
    ai = {
      description = "Домен «ИИ-сервисы»"
      cores       = 4
      memory      = 8
      disk_size   = 30
      subnet      = "private"
    }
  }
}

variable "etl_vm" {
  description = "Параметры VM слоя интеграции данных (ETL)"
  type = object({
    cores     = number
    memory    = number
    disk_size = number
  })
  default = {
    cores     = 4
    memory    = 8
    disk_size = 30
  }
}

variable "etl_staging_disk_size" {
  description = "Размер диска для стейджинга данных ETL, ГБ"
  type        = number
  default     = 100
}

variable "vpn_peer_ip" {
  description = "Публичный IP-адрес on-premise стороны для site-to-site VPN до Legacy DWH"
  type        = string
}

variable "clickhouse_resource_preset_id" {
  description = "Класс хоста Managed ClickHouse"
  type        = string
  default     = "s2.medium"
}

variable "clickhouse_disk_type" {
  description = "Тип диска Managed ClickHouse"
  type        = string
  default     = "network-ssd"
}

variable "clickhouse_disk_size" {
  description = "Размер диска Managed ClickHouse, ГБ"
  type        = number
  default     = 100
}

variable "clickhouse_db_name" {
  description = "Имя базы данных аналитической витрины"
  type        = string
  default     = "analytics_mart"
}

variable "clickhouse_user" {
  description = "Имя пользователя Managed ClickHouse"
  type        = string
  default     = "analytics_admin"
}

variable "clickhouse_password" {
  description = "Пароль пользователя Managed ClickHouse"
  type        = string
  sensitive   = true
}
