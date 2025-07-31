bucket         = "tf-nh"
key            = "kiro-tf-bia/prod/terraform.tfstate"
region         = "us-east-1"
encrypt        = true
# dynamodb_table removed - using S3 object locking instead