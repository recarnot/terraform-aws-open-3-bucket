provider "aws" {
  profile = "open"
  region  = "eu-west-1"
}

module "storage" {
  source = "../"

  prefix     = "myprefix"
  acl        = "private"
  versioning = true
  logs       = true
  encryption = true
  transition_30_days = true
  transition_60_days = true
  transition_90_days = true
}