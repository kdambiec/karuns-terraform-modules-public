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

variable "source_bucket_arn" {
  description = "Source Bucket ARN"
  type        = string
}

variable "destination_bucket_arn" {
  description = "Destination Bucket ARN"
  type        = string
}

variable "source_bucket_id" {
  description = "Source Bucket ID"
  type        = string
}

variable "delete_marker_replication_enabled" {
  description = "Delete Marker Replication Enabled"
  type        = string
}

variable "destination_storage_class" {
  description = "Destination Storage Class"
  type        = string
}