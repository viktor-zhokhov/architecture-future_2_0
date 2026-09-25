terraform {
  required_version = ">= 1.5.0"

  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = ">= 0.100.0"
    }
  }
}

provider "yandex" {
  token     = var.yc_token
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
  zone      = var.zone
}

# --- Сеть (Terraform) ---

resource "yandex_vpc_network" "main" {
  name = var.network_name
}

resource "yandex_vpc_subnet" "public" {
  name           = "${var.network_name}-public"
  zone           = var.zone
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = [var.public_subnet_cidr]
}

resource "yandex_vpc_subnet" "private" {
  name           = "${var.network_name}-private"
  zone           = var.zone
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = [var.private_subnet_cidr]
}

resource "yandex_vpc_security_group" "main" {
  name       = "${var.network_name}-sg"
  network_id = yandex_vpc_network.main.id

  ingress {
    protocol       = "TCP"
    description    = "HTTPS от бизнес-пользователей к порталу"
    port           = 443
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "TCP"
    description    = "SSH для администрирования"
    port           = 22
    v4_cidr_blocks = [var.admin_cidr]
  }

  ingress {
    protocol       = "TCP"
    description    = "внутренний трафик между доменными сервисами"
    from_port      = 0
    to_port        = 65535
    v4_cidr_blocks = [var.public_subnet_cidr, var.private_subnet_cidr]
  }

  egress {
    protocol       = "ANY"
    description    = "исходящий трафик"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- Вычислительные ресурсы доменов (Terraform) ---

resource "yandex_compute_instance" "domain_vm" {
  for_each = var.domain_vms

  name        = "future20-${each.key}"
  description = each.value.description
  zone        = var.zone

  resources {
    cores  = each.value.cores
    memory = each.value.memory
  }

  boot_disk {
    initialize_params {
      image_id = var.vm_image_id
      size     = each.value.disk_size
    }
  }

  network_interface {
    subnet_id          = each.value.subnet == "public" ? yandex_vpc_subnet.public.id : yandex_vpc_subnet.private.id
    security_group_ids = [yandex_vpc_security_group.main.id]
    nat                = each.value.subnet == "public"
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.ssh_public_key_path)}"
  }
}

# --- Слой интеграции данных (ETL) с отдельным диском для стейджинга (Terraform) ---

resource "yandex_compute_disk" "etl_staging" {
  name = "future20-etl-staging"
  zone = var.zone
  size = var.etl_staging_disk_size
  type = "network-ssd"
}

resource "yandex_compute_instance" "etl" {
  name        = "future20-etl"
  description = "Слой интеграции данных (ETL/ELT)"
  zone        = var.zone

  resources {
    cores  = var.etl_vm.cores
    memory = var.etl_vm.memory
  }

  boot_disk {
    initialize_params {
      image_id = var.vm_image_id
      size     = var.etl_vm.disk_size
    }
  }

  secondary_disk {
    disk_id = yandex_compute_disk.etl_staging.id
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.private.id
    security_group_ids = [yandex_vpc_security_group.main.id]
    nat                = false
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.ssh_public_key_path)}"
  }
}

# --- VPN-шлюз до on-premise Legacy DWH (Terraform, облачная сторона) ---

resource "yandex_compute_instance" "vpn_gateway" {
  name        = "future20-vpn-gateway"
  description = "Облачный конец site-to-site VPN до Legacy DWH"
  zone        = var.zone

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = var.vm_image_id
      size     = 20
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.public.id
    security_group_ids = [yandex_vpc_security_group.main.id]
    nat                = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.ssh_public_key_path)}"
    # Настройка VPN-туннеля (WireGuard/StrongSwan) до on-premise выполняется
    # вручную после создания VM — конкретные ключи и правила туннеля не
    # являются частью инфраструктурной автоматизации.
    vpn-peer-ip = var.vpn_peer_ip
  }
}

# --- Балансировщик нагрузки для портала самообслуживания (Terraform) ---

resource "yandex_lb_target_group" "portal" {
  name      = "future20-portal-tg"
  region_id = var.region_id

  target {
    subnet_id = yandex_vpc_subnet.public.id
    address   = yandex_compute_instance.domain_vm["portal"].network_interface[0].ip_address
  }
}

resource "yandex_lb_network_load_balancer" "portal_lb" {
  name = "future20-portal-lb"

  listener {
    name = "portal-https"
    port = 443
    external_address_spec {
      ip_version = "ipv4"
    }
  }

  attached_target_group {
    target_group_id = yandex_lb_target_group.portal.id

    healthcheck {
      name = "http-health"
      http_options {
        port = 80
        path = "/healthz"
      }
    }
  }
}

# --- Аналитическое хранилище: Managed ClickHouse (Terraform) ---

resource "yandex_mdb_clickhouse_cluster_v2" "analytics" {
  name        = "future20-analytics-dwh"
  environment = "PRODUCTION"
  network_id  = yandex_vpc_network.main.id

  clickhouse = {
    resources = {
      resource_preset_id = var.clickhouse_resource_preset_id
      disk_type_id       = var.clickhouse_disk_type
      disk_size          = var.clickhouse_disk_size
    }
  }

  shards = {
    "shard1" = {}
  }

  hosts = {
    "clickhouse-a" = {
      type       = "CLICKHOUSE"
      zone       = var.zone
      subnet_id  = yandex_vpc_subnet.private.id
      shard_name = "shard1"
    }
  }

  maintenance_window {
    type = "ANYTIME"
  }

  admin_password = var.clickhouse_password

  security_group_ids = [yandex_vpc_security_group.main.id]
}

resource "yandex_mdb_clickhouse_database" "analytics_mart" {
  cluster_id = yandex_mdb_clickhouse_cluster_v2.analytics.id
  name       = var.clickhouse_db_name
}

resource "yandex_mdb_clickhouse_user" "analytics_admin" {
  cluster_id = yandex_mdb_clickhouse_cluster_v2.analytics.id
  name       = var.clickhouse_user
  password   = var.clickhouse_password

  permission {
    database_name = yandex_mdb_clickhouse_database.analytics_mart.name
  }
}
