terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
      version = "0.99.1"
    }
  }
}

locals {
    folder_id = "b1gneo9mi2c02taf7erq"
    cloud_id = "b1g45l8iihfq58urlhtv"
}
provider "yandex" {
  cloud_id = local.cloud_id
  folder_id = local.folder_id
  service_account_key_file = "/diplom/terraform/key/authorized_key.json"
}
