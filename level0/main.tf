#create s3 bucket to store state file
resource "aws_s3_bucket" "bucket" {
  bucket = "task2-store-tfstate"

  versioning {
    enabled = true
  }

}

#create dynamodb table to lock the state file
resource "aws_dynamodb_table" "terraform_lock" {
  name           = "tfstate"
  read_capacity  = 5
  write_capacity = 5
  hash_key       = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }
  tags = {
    "Name" = "DynamoDB Terraform State Lock Table"
  }
}
