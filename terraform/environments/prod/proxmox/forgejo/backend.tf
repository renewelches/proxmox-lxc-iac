terraform {
  backend "s3" {
    bucket = "terraform-state"
    key    = "proxmox/forgejo/terraform.tfstate"
    region = "us-east-1"

    endpoints = {
      s3 = "https://minio.grumples.home:9000"
    }

    access_key = "EEAXLLTBLT1Y2RYC90BZ"
    secret_key = "26bJxz+YBveK+oUFPwgh0eNOvvncmF0HJNs9nc4l"

    use_path_style              = true
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true

    use_lockfile = true
  }
}
