resource "aws_dynamodb_table" "dynamo-table-terraform-state-locking" {
  name         = "${var.env}-terraform-state-locking"
  hash_key     = "LockID"
  billing_mode = "PAY_PER_REQUEST"

  attribute {
    name = "LockID"
    type = "S"
  }
}
