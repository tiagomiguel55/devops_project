# state.tf
terraform {
  backend "s3" {
    bucket  = "terraform-state-tiagomiguel"
    key     = "site/terraform.tfstate"
    region  = "eu-west-3"
    encrypt = true // optional, but recommended to encrypt the state file
  }
}
