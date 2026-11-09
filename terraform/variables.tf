variable "proxmox_endpoint" {
  type = string
}

variable "proxmox_api_token" {
  type        = string
  sensitive   = true
  description = "user@realm!tokenid=secret"
}

variable "node" {
  type    = string
  default = "squirtle"
}

variable "storage" {
  type    = string
  default = "competitions"
}

variable "vm_id" {
  type        = number
  default     = null
  description = "null = next free ID"
}
