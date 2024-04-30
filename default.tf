terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "0.115.0"
    }
  }
}

locals {
  folder_id = "b1gqgvge6c6cd6sori4l"
  cloud_id  = "b1goa1cerssml2sm8ej5"
}

provider "yandex" {
  cloud_id                 = local.cloud_id
  folder_id                = local.folder_id
  service_account_key_file = "/home/user/authorized_key.json"
}


