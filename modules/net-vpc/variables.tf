/**
 * Copyright 2021 Google LLC
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

variable "auto_create_subnetworks" {
  description = "Set to true to create an auto mode subnet, defaults to custom mode."
  type        = bool
  default     = false
}

variable "delete_default_routes_on_create" {
  description = "Set to true to delete the default routes at creation time."
  type        = bool
  default     = false
}

variable "description" {
  description = "An optional description of this resource (triggers recreation on change)."
  type        = string
  default     = "Terraform-managed."
}

variable "iam" {
  description = "Subnet IAM bindings in {REGION/NAME => {ROLE => [MEMBERS]} format."
  type        = map(map(list(string)))
  default     = {}
}

variable "mtu" {
  description = "Maximum Transmission Unit in bytes. The minimum value for this field is 1460 and the maximum value is 1500 bytes."
  default     = null
}

variable "name" {
  description = "The name of the network being created"
  type        = string
}

variable "peering_config" {
  description = "VPC peering configuration."
  type = object({
    peer_vpc_self_link = string
    export_routes      = bool
    import_routes      = bool
  })
  default = null
}

variable "peering_create_remote_end" {
  description = "Skip creation of peering on the remote end when using peering_config"
  type        = bool
  default     = true
}

variable "project_id" {
  description = "The ID of the project where this VPC will be created"
  type        = string
}

variable "routes" {
  description = "Network routes, keyed by name."
  type = map(object({
    dest_range    = string
    priority      = number
    tags          = list(string)
    next_hop_type = string # gateway, instance, ip, vpn_tunnel, ilb
    next_hop      = string
  }))
  default = {}
}

variable "routing_mode" {
  description = "The network routing mode (default 'GLOBAL')"
  type        = string
  default     = "GLOBAL"
  validation {
    condition     = var.routing_mode == "GLOBAL" || var.routing_mode == "REGIONAL"
    error_message = "Routing type must be GLOBAL or REGIONAL."
  }
}

variable "shared_vpc_host" {
  description = "Enable shared VPC for this project."
  type        = bool
  default     = false
}

variable "shared_vpc_service_projects" {
  description = "Shared VPC service projects to register with this host"
  type        = list(string)
  default     = []
}

variable "subnets" {
  description = "The list of subnets being created"
  type = list(object({
    name               = string
    ip_cidr_range      = string
    name               = string
    region             = string
    secondary_ip_range = optional(map(string))
    description        = optional(string)
    flow_logs = optional(object({
      aggregation_interval = string
      flow_sampling        = number
      metadata             = string
    }))
    private_access = optional(bool)
  }))
  default = []
}

variable "vpc_create" {
  description = "Create VPC. When set to false, uses a data source to reference existing VPC."
  type        = bool
  default     = true
}
