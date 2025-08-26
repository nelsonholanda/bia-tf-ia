bucket         = "tf-nh"
key            = "bia-ia/prod/terraform.tfstate"
region         = "us-east-1"
encrypt        = true
# dynamodb_table removed - using S3 object locking instead