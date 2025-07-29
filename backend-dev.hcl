bucket         = "tf-nh"
key            = "kiro-tf-bia/dev/terraform.tfstate"
region         = "us-east-1"
encrypt        = true
dynamodb_table = "terraform-state-lock-bia-dev"