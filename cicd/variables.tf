# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


variable "project_name" {
  description = "Project name of the devops project to host CI/CD resources"
  type        = string
  default     = ""
}

variable "default_region" {
  description = "Default region to create resources where applicable."
  type        = string
  default     = "us-central1"
}

variable "org_id" {
  description = "GCP Organization ID"
  type        = string
  default     = ""
}

variable "folder_id" {
  description = "The ID of a folder to host this project"
  type        = string
  default     = ""
}

variable "billing_account" {
  description = "The ID of the billing account to associate this project with"
  type        = string
}

variable "parent_folder" {
  description = "GCP parent folder ID in the form folders/{id}"
  default     = ""
  type        = string
}

variable "project_labels" {
  description = "Labels to apply to the project."
  type        = map(string)
  default     = {}
}

variable "project_prefix" {
  description = "Name prefix to use for projects created."
  type        = string
  default     = "prj"
}

variable "auto_create_network" {
  description = "Create the default network"
  type        = bool
  default     = false
}

variable "cloudbuild_viewers" {
  description = "groups to add as a viewer/reader in group:groupname@domain.com format"
  type        = list(any)
  default     = []
}

variable "cloudbuild_editors" {
  description = "groups to add as a editor/writer in group:groupname@domain.com format"
  type        = list(any)
  default     = []
}
