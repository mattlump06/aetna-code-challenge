run "s3_bucket_encryption_enabled" {
  module {
    source = "./modules/s3"
  }

  variables {
    app_name    = "test-app"
    environment = "test"
  }

  assert {
    condition     = aws_s3_bucket_server_side_encryption_configuration.main.rule[0].apply_server_side_encryption_by_default[0].sse_algorithm == "AES256"
    error_message = "S3 bucket encryption is not enabled"
  }
}

run "s3_bucket_versioning_enabled" {
  module {
    source = "./modules/s3"
  }

  variables {
    app_name    = "test-app"
    environment = "test"
  }

  assert {
    condition     = aws_s3_bucket_versioning.main.versioning_configuration[0].status == "Enabled"
    error_message = "S3 bucket versioning is not enabled"
  }
}

run "s3_bucket_public_access_blocked" {
  module {
    source = "./modules/s3"
  }

  variables {
    app_name    = "test-app"
    environment = "test"
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.main.block_public_acls == true && aws_s3_bucket_public_access_block.main.block_public_policy == true && aws_s3_bucket_public_access_block.main.ignore_public_acls == true && aws_s3_bucket_public_access_block.main.restrict_public_buckets == true
    error_message = "S3 bucket public access is not properly blocked"
  }
}

