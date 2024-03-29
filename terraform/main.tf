provider "yandex" {
  token = ""
  cloud_id                 = "b1gfodjsfjm1ue7u0ld7"
  folder_id                = "b1ggthdvv3nparichh2u"
  zone                     = "ru-central1-a"
}

data "yandex_compute_image" "ubuntu" {
  family = "centos-7"
}

data "yandex_vpc_subnet" "subnet" {
  name = "dn-subnet"
}

locals {
  ssh_user = "centos"
}


resource "yandex_compute_instance" "node" {
  for_each = {
    grafana = "grafana",
  }
  name = each.value
  resources {
    cores  = 2
    memory = 2
  }

  network_interface {
    subnet_id = data.yandex_vpc_subnet.subnet.id
    nat = true
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
    }
  }
  metadata = {
    type      = each.key
    ssh-keys = "${local.ssh_user}:${file("~/.ssh/id_rsa.pub")}"
  }
}

resource "local_file" "inventory" {
    filename = "./hosts.yaml"
    content     = <<-EOF
    %{ for instance in yandex_compute_instance.node }
    ${instance.metadata.type}:
      hosts:
        ${instance.name}:
          ansible_host: ${instance.network_interface.0.nat_ip_address}
          ansible_user: ${local.ssh_user}
    %{ endfor }
    EOF
}
