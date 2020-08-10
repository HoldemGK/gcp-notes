/**
 * Copyright 2018 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

variable "project_id" {
  description = "The project ID to deploy to"
  default     = ""
}

variable "machine_type" {
  description = "The GCP machine type to deploy"
  default     = "f1-micro"
}

variable "zone" {
  description = "The zone to create the instance"
  default     = "us-central1-f"
}

variable "network_name" {
  description = "Network name"
  default     = "default"
}

variable "port" {
  description = "List of ports number"
}

variable "ip_protocol" {
  description = "Type IP protocol"
  default     = "tcp"
}

variable "source_ranges" {
  description = "Network range of source"
  default     = "0.0.0.0/0"
}

variable "target_tags" {
  default = "redis_inst"
}

