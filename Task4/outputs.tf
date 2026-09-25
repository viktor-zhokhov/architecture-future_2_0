output "network_id" {
  description = "Идентификатор VPC-сети"
  value       = yandex_vpc_network.main.id
}

output "public_subnet_id" {
  description = "Идентификатор публичной подсети"
  value       = yandex_vpc_subnet.public.id
}

output "private_subnet_id" {
  description = "Идентификатор приватной подсети"
  value       = yandex_vpc_subnet.private.id
}

output "domain_vm_internal_ips" {
  description = "Внутренние IP-адреса доменных VM (портал, шина, финтех, ИИ)"
  value       = { for key, vm in yandex_compute_instance.domain_vm : key => vm.network_interface[0].ip_address }
}

output "domain_vm_external_ips" {
  description = "Внешние IP-адреса доменных VM (если назначены, например у портала)"
  value       = { for key, vm in yandex_compute_instance.domain_vm : key => try(vm.network_interface[0].nat_ip_address, null) }
}

output "etl_vm_internal_ip" {
  description = "Внутренний IP-адрес VM слоя интеграции данных (ETL)"
  value       = yandex_compute_instance.etl.network_interface[0].ip_address
}

output "etl_staging_disk_id" {
  description = "Идентификатор диска стейджинга ETL"
  value       = yandex_compute_disk.etl_staging.id
}

output "vpn_gateway_external_ip" {
  description = "Внешний IP-адрес облачного конца VPN-туннеля (для настройки на стороне on-premise)"
  value       = yandex_compute_instance.vpn_gateway.network_interface[0].nat_ip_address
}

output "portal_load_balancer_ip" {
  description = "Внешний IP-адрес балансировщика нагрузки портала самообслуживания"
  value       = flatten([for l in yandex_lb_network_load_balancer.portal_lb.listener : [for a in l.external_address_spec : a.address]])[0]
}

output "clickhouse_cluster_id" {
  description = "Идентификатор кластера Managed ClickHouse (аналитическое хранилище)"
  value       = yandex_mdb_clickhouse_cluster_v2.analytics.id
}

output "clickhouse_hosts" {
  description = "FQDN хостов кластера Managed ClickHouse для подключения из слоя интеграции данных и портала"
  value       = [for h in values(yandex_mdb_clickhouse_cluster_v2.analytics.hosts) : h.fqdn]
}
