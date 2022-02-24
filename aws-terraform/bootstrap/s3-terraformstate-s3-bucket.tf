module "terraform-state-bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "2.11.1"

  bucket = "${var.env}-${var.project}-terraform-state"
  acl    = "private"

  versioning = {
    enabled = true
  }

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }
}