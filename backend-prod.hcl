bucket         = "tf-nh"
key            = "kiro-tf-bia/prod/terraform.tfstate"
region         = "us-east-1"
encrypt        = true
dynamodb_table = "terraform-state-lock-bia-prod"