# Remote Terraform State Backend (Amazon S3 + DynamoDB State Locking)
# Bootstrap workflow:
# 1. Deploy module.s3_backend first using local state: terraform apply -target=module.s3_backend
# 2. Uncomment the terraform { backend "s3" { ... } } block below
# 3. Migrate state to S3: terraform init -migrate-state

# terraform {
#   backend "s3" {
#     bucket         = "vlad-popov-terraform-state-us-west-2"
#     key            = "lesson-db-module/terraform.tfstate"
#     region         = "us-west-2"
#     dynamodb_table = "terraform-locks"
#     encrypt        = true
#   }
# }
