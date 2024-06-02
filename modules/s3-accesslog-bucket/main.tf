terraform {
  required_providers {
    aws = {
      // The source attribute defines where the AWS provider can be downloaded from.
      source = "hashicorp/aws"
    }
  }
}

// Define an AWS S3 bucket
resource "aws_s3_bucket" "bucket" {
  bucket = "${var.bucket_name}-us-west-2" // Set the bucket name
  tags = {
    ClumioBackup = "disabled" // Add a tag to disable Clumio Backups
  }
  lifecycle {
    prevent_destroy = true // Lifecycle rule to prevent accidental deletion
  }
}

// Enable versioning on the S3 bucket
resource "aws_s3_bucket_versioning" "bucket" {
  bucket = aws_s3_bucket.bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

// Retrieve the default AWS KMS key for S3 in the Oregon region
data "aws_kms_alias" "oregon_s3_kms_key" {
  name = "alias/aws/s3"
}

// Enable server side encryption for the S3 Acces Log Bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "bucket" {
  bucket = aws_s3_bucket.bucket.id
  // Rule to apply server side encryption by default
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

// Disable acceleration on the S3 bucket
resource "aws_s3_bucket_accelerate_configuration" "bucket" {
  bucket = aws_s3_bucket.bucket.id
  status = "Suspended"
}

// Set bucket ownership rules
resource "aws_s3_bucket_ownership_controls" "bucket" {
  bucket = aws_s3_bucket.bucket.id
  rule {
    object_ownership = "BucketOwnerEnforced" // Object ownership is enforced to the bucket owner
  }
}

// Block public access to the S3 bucket
resource "aws_s3_bucket_public_access_block" "bucket" {
  bucket                  = aws_s3_bucket.bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

// Define lifecycle rules for the S3 bucket
resource "aws_s3_bucket_lifecycle_configuration" "bucket" {
  bucket = aws_s3_bucket.bucket.id
  rule {
    id = "rule-1"
    filter {}
    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }
    expiration {
      days = 366
    }
    noncurrent_version_expiration {
      noncurrent_days = 30
    }
    transition {
      storage_class = "INTELLIGENT_TIERING"
      days          = 1
    }
    noncurrent_version_transition {
      storage_class   = "INTELLIGENT_TIERING"
      noncurrent_days = 1
    }
    status = "Enabled"
  }
}

data "aws_caller_identity" "current_oregon" {}

// Bucket Policy to Allow S3 Access Logs to be written to the bucket
data "aws_iam_policy_document" "s3_accesslogs_bucket_policy" {
  statement {
    sid    = "S3ServerAccessLogsPolicy"
    effect = "Allow"
    principals {
      identifiers = ["logging.s3.amazonaws.com"]
      type        = "Service"
    }
    actions = [
      "s3:PutObject"
    ]
    resources = [
      "${aws_s3_bucket.bucket.arn}/*"
    ]
    condition {
      test = "StringEquals"
      values = [
        data.aws_caller_identity.current_oregon.account_id
      ]
      variable = "aws:SourceAccount"
    }
  }
}

// Bucket Policy to Allow S3 Access Logs to be written to the bucket
resource "aws_s3_bucket_policy" "s3_accesslogs_bucket_policy" {
  bucket = aws_s3_bucket.bucket.id
  policy = data.aws_iam_policy_document.s3_accesslogs_bucket_policy.json
}

# Enable Archive Levels for S3 Access Logs Bucket
resource "aws_s3_bucket_intelligent_tiering_configuration" "bucket" {
  bucket = aws_s3_bucket.bucket.id
  name   = "EntireBucket"
  tiering {
    access_tier = "ARCHIVE_ACCESS"
    days        = 90
  }
  tiering {
    access_tier = "DEEP_ARCHIVE_ACCESS"
    days        = 180
  }
}