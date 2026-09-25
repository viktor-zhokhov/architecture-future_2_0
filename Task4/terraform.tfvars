# Учётные данные и идентификаторы облака — замените на реальные значения вашего аккаунта Yandex Cloud
yc_token  = "REPLACE_WITH_YC_OAUTH_TOKEN"
cloud_id  = "REPLACE_WITH_CLOUD_ID"
folder_id = "REPLACE_WITH_FOLDER_ID"

zone      = "ru-central1-a"
region_id = "ru-central1"

network_name        = "future20-network"
public_subnet_cidr  = "10.0.1.0/24"
private_subnet_cidr = "10.0.2.0/24"
admin_cidr          = "203.0.113.0/32"

vm_image_id         = "fd8vqmftm8ff65rkfsti" # Ubuntu 22.04 LTS в каталоге образов Yandex Cloud
ssh_public_key_path = "~/.ssh/id_rsa.pub"

vpn_peer_ip = "198.51.100.10" # публичный IP on-premise стороны (Legacy DWH)

clickhouse_resource_preset_id = "s2.medium"
clickhouse_disk_type          = "network-ssd"
clickhouse_disk_size          = 100
clickhouse_db_name            = "analytics_mart"
clickhouse_user               = "analytics_admin"
clickhouse_password           = "REPLACE_WITH_STRONG_PASSWORD"
