# Copyright 2024 Karun Dambiec
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

terraform {
  required_providers {
    aws = {
      // The source attribute defines where the AWS provider can be downloaded from.
      source = "hashicorp/aws"
    }
  }
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "replication" {
  statement {
    effect = "Allow"

    actions = [
      "s3:GetReplicationConfiguration",
      "s3:ListBucket",
    ]

    resources = [var.source_bucket_arn]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:GetObjectVersionForReplication",
      "s3:GetObjectVersionAcl",
      "s3:GetObjectVersionTagging",
    ]

    resources = ["${var.source_bucket_arn}/*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:ReplicateObject",
      "s3:ReplicateDelete",
      "s3:ReplicateTags",
    ]

    resources = ["${var.destination_bucket_arn}/*"]
  }
}

resource "aws_iam_policy" "replication" {
  policy = data.aws_iam_policy_document.replication.json
}

resource "aws_iam_role" "replication" {
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  managed_policy_arns = [
    aws_iam_policy.replication.arn
  ]
}

resource "aws_s3_bucket_replication_configuration" "replication" {
  bucket = var.source_bucket_id
  role   = aws_iam_role.replication.arn

  rule {
    status = "Enabled"
    filter {}
    delete_marker_replication {
      status = var.delete_marker_replication_enabled ? "Enabled" : "Disabled"
    }
    destination {
      access_control_translation {
        owner = "Destination"
      }
      bucket        = var.destination_bucket_arn
      storage_class = var.destination_storage_class
    }
  }
}