resource "yandex_vpc_network" "network-vm" {
  name           = "network"
  description    = "Общая сеть для размещения всех ресурсов"
}
resource "yandex_vpc_subnet" "subnet-vm1" {
  name           = "subnetwebsite1"
  description    = "Подсеть ВМ vm1"
  zone           = "ru-central1-a"
  v4_cidr_blocks = ["192.168.10.0/24"]
  network_id     = yandex_vpc_network.network-vm.id
  route_table_id = yandex_vpc_route_table.inner-to-nat.id
}
resource "yandex_vpc_subnet" "subnet-vm2" {
  name           = "subnetwebsite2"
  description    = "Подсеть ВМ vm2"
  zone           = "ru-central1-b"
  v4_cidr_blocks = ["192.168.20.0/24"]
  network_id     = yandex_vpc_network.network-vm.id
  route_table_id = yandex_vpc_route_table.inner-to-nat.id
}
resource "yandex_vpc_subnet" "subnet-inside" {     
  name           = "subnetinside" 
  description    = "Подсеть балансировщика"
  zone           = "ru-central1-c" 
  network_id     = yandex_vpc_network.network-vm.id 
  v4_cidr_blocks = ["192.168.30.0/24"]
  route_table_id = yandex_vpc_route_table.inner-to-nat.id
}
resource "yandex_vpc_subnet" "subnet-bastion" {
  name           = "subnetbastion"
  description    = "Подсеть ВМ bastion"
  zone           = "ru-central1-c"
  v4_cidr_blocks = ["192.168.40.0/24"]
  network_id     = yandex_vpc_network.network-vm.id
}





resource "yandex_vpc_route_table" "inner-to-nat" {
  network_id = yandex_vpc_network.network-vm.id 
  static_route {
    destination_prefix = "0.0.0.0/0" 
    next_hop_address = yandex_compute_instance.bastion.network_interface.0.ip_address
  }
}





resource "yandex_vpc_security_group" "inside" {  
  name       = "inside"
  description = "Без ограничений внутри подсетей"
  network_id = yandex_vpc_network.network-vm.id
  ingress {
    protocol       = "ANY"
    v4_cidr_blocks = ["192.168.0.0/16"]
   }
  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "yandex_vpc_security_group" "bastion" {
  name = "bastion public" 
  description = "Разрешение на подключение к ВМ bastion по SSH из сети Интернет"
  network_id = yandex_vpc_network.network-vm.id 
  ingress {
    protocol = "TCP" 
    description = "allow SSH connections from internet" 
    v4_cidr_blocks = ["0.0.0.0/0"]
    port = 22
  }
  ingress {
    protocol = "ICMP" 
    description = "allow ping" 
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    protocol = "ANY" 
    description = "allow any outgoing connection" 
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "yandex_vpc_security_group" "kibana" {
  name = "kibana public" 
  description = "Разрешение на подключение к kibana из сети Интернет"
  network_id = yandex_vpc_network.network-vm.id 
  ingress {
    protocol = "TCP" 
    description = "allow kibana connections from internet" 
    v4_cidr_blocks = ["0.0.0.0/0"]
    port = 5601
  }

  ingress {
    protocol = "ICMP" 
    description = "allow ping" 
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    protocol = "ANY" 
    description = "allow any outgoing connection" 
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "yandex_vpc_security_group" "zabbix" {
  name = "zabbix public" 
  description = "Разрешение на подключение к zabbix из сети Интернет"
  network_id = yandex_vpc_network.network-vm.id 
  ingress {
    protocol = "TCP" 
    description = "allow zabbix connections from internet" 
    v4_cidr_blocks = ["0.0.0.0/0"]
    port = 80
  }
  ingress {
    protocol = "ICMP" 
    description = "allow ping" 
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    protocol = "ANY" 
    description = "allow any outgoing connection" 
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "yandex_vpc_security_group" "balancer" {  
  name = "balancer public"
  description =  "Разрешение на подключение к alb из сети Инертнет по HHTP (80)" 
  network_id = yandex_vpc_network.network-vm.id 
  ingress {
    protocol = "ANY" 
    description = "Health checks"
    v4_cidr_blocks = ["0.0.0.0/0"]
    predefined_target = "loadbalancer_healthchecks"
  }
  ingress {
    protocol = "TCP" 
    description = "allow HTTP connections from internet" 
    v4_cidr_blocks = ["0.0.0.0/0"]
    port = 80
  }
  ingress {
    protocol = "ICMP" 
    description = "allow ping" 
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    protocol = "ANY" 
    description = "allow any outgoing connection" 
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}





resource "yandex_compute_instance" "bastion" {
  name                      = "bastion"
  hostname                  = "bastion"
  platform_id               = "standard-v3"
  zone                      = "ru-central1-c"
  resources {
    cores  = "2"
    memory = "2"
  }
  boot_disk {
    initialize_params {
      image_id = "fd8tkfhqgbht3sigr37c"
    }
  }
    network_interface {
    subnet_id = yandex_vpc_subnet.subnet-bastion.id
    nat = true 
    security_group_ids = [yandex_vpc_security_group.bastion.id]
    ip_address = "192.168.40.100"
  }
    metadata = {
    user-data = "${file("/diplom/terraform/key/metadata.yaml")}"
  }
}
resource "yandex_compute_instance" "elasticsearch" {
  name                      = "elasticsearch"
  hostname                  = "elasticsearch"
  platform_id               = "standard-v3"
  zone                      = "ru-central1-c"
  resources {
    cores  = "2"
    memory = "2"
  }
  boot_disk {
    initialize_params {
      image_id = "fd8tkfhqgbht3sigr37c"
    }
  }
    network_interface {
    subnet_id = yandex_vpc_subnet.subnet-inside.id
    security_group_ids = [yandex_vpc_security_group.zabbix.id, yandex_vpc_security_group.inside.id]
    ip_address = "192.168.30.101"        
  }
    metadata = {
    user-data = "${file("/diplom/terraform/key/metadata.yaml")}"
}
}
resource "yandex_compute_instance" "zabbix" {
  name                      = "zabbix"
  hostname                  = "zabbix"
  platform_id               = "standard-v3"
  zone                      = "ru-central1-c"
  resources {
    cores  = "2"
    memory = "2"
  }
  boot_disk {
    initialize_params {
      image_id = "fd8tkfhqgbht3sigr37c"
    }
  }
    network_interface {
    subnet_id = yandex_vpc_subnet.subnet-inside.id
    nat = true 
    security_group_ids = [yandex_vpc_security_group.zabbix.id, yandex_vpc_security_group.inside.id]
    ip_address = "192.168.30.102"
  }
    metadata = {
    user-data = "${file("/diplom/terraform/key/metadata.yaml")}"
}
}
resource "yandex_compute_instance" "kibana" {
  name                      = "kibana"
  hostname                  = "kibana"
  platform_id               = "standard-v3"
  zone                      = "ru-central1-c"
  resources {
    cores  = "2"
    memory = "2"
  }
  boot_disk {
    initialize_params {
      image_id = "fd8tkfhqgbht3sigr37c"
    }
  }
    network_interface {
    subnet_id = yandex_vpc_subnet.subnet-inside.id
    nat = true 
    security_group_ids = [yandex_vpc_security_group.kibana.id, yandex_vpc_security_group.inside.id]
    ip_address = "192.168.30.103"
  }
    metadata = {
    user-data = "${file("/diplom/terraform/key/metadata.yaml")}"
}
}





resource "yandex_compute_instance" "vm1" {
  name                      = "website1"
  hostname                  = "website1"
  platform_id               = "standard-v3"
  zone                      = "ru-central1-a"
  allow_stopping_for_update = true
  resources {
    cores  = "2"
    memory = "2"
  }
  boot_disk {
    initialize_params {
      image_id = "fd8tkfhqgbht3sigr37c"
    }
  }
    network_interface {
    subnet_id = yandex_vpc_subnet.subnet-vm1.id
    security_group_ids = [yandex_vpc_security_group.inside.id]
    ip_address = "192.168.10.100"               
  }
    metadata = {
    user-data = "${file("/diplom/terraform/key/metadata.yaml")}"
}
}
resource "yandex_compute_instance" "vm2" {
  name                      = "website2"
  hostname                  = "website2"
  platform_id               = "standard-v3"
  zone                      = "ru-central1-b"
  allow_stopping_for_update = true
  resources {
    cores  = "2"
    memory = "2"
  }
  boot_disk {
    initialize_params {
      image_id = "fd8tkfhqgbht3sigr37c"
    }
  }
    network_interface {
    subnet_id = yandex_vpc_subnet.subnet-vm2.id
    security_group_ids = [yandex_vpc_security_group.inside.id]
    ip_address = "192.168.20.100"                
  }
    metadata = {
    user-data = "${file("/diplom/terraform/key/metadata.yaml")}"
  }
}
resource "yandex_alb_target_group" "albtggr" {
name      = "albtggr"
  target {
    subnet_id = yandex_vpc_subnet.subnet-vm1.id
    ip_address   = yandex_compute_instance.vm1.network_interface.0.ip_address
  }
  target {
    subnet_id = yandex_vpc_subnet.subnet-vm2.id
    ip_address   = yandex_compute_instance.vm2.network_interface.0.ip_address
  }
}
resource "yandex_alb_backend_group" "albbckgr" {
  name                     = "albbckgr"  
  http_backend {
    name                   = "httpbck"
    weight                 = 1
    port                   = 80
    target_group_ids       = [yandex_alb_target_group.albtggr.id]
    load_balancing_config {
      panic_threshold = 90
    }
    healthcheck {
      healthcheck_port = 80
      timeout              = "10s"
      interval             = "2s"
      healthy_threshold    = 10
      unhealthy_threshold  = 15 
      http_healthcheck {
        path               = "/"
      }
    }
  }
}
resource "yandex_alb_http_router" "albhttprt" {
  name          = "albhttprt"
}
resource "yandex_alb_virtual_host" "albvtht" {
  name                    = "albvtht"
  http_router_id          = yandex_alb_http_router.albhttprt.id
  route {
    name                  = "route"
    http_route {
      http_match {
        path {
          prefix = "/"
        }
      }
      http_route_action {
        backend_group_id  = yandex_alb_backend_group.albbckgr.id
        timeout           = "60s"
      }
    }
  }
}  
resource "yandex_alb_load_balancer" "alblb" {
  name        = "alblb"
  network_id  = yandex_vpc_network.network-vm.id
  security_group_ids = [yandex_vpc_security_group.inside.id, yandex_vpc_security_group.balancer.id]
  allocation_policy {
    location     {  
       zone_id   = "ru-central1-c"
       subnet_id = yandex_vpc_subnet.subnet-inside.id  
       }
  }
  listener {
    name = "list"
    endpoint {
      address {
        external_ipv4_address {
        }
      }
      ports = [80]
    }
    http {
      handler {
        http_router_id = yandex_alb_http_router.albhttprt.id
      }
    }
  }
}

resource "yandex_compute_snapshot_schedule" "snapshot" {
  name = "snapshot"
  schedule_policy {
    expression = "0 0 ? * *"
  }
  snapshot_count = 7
  snapshot_spec {
    description = "daily-snapshot"
  }
  disk_ids = [yandex_compute_instance.bastion.boot_disk.0.disk_id, yandex_compute_instance.zabbix.boot_disk.0.disk_id, yandex_compute_instance.elasticsearch.boot_disk.0.disk_id, yandex_compute_instance.kibana.boot_disk.0.disk_id, yandex_compute_instance.vm1.boot_disk.0.disk_id, yandex_compute_instance.vm2.boot_disk.0.disk_id]
}




