variable "kv_admins" {
  description = "List of admin user IDs for the Key Vault"
  type        = list(string)
}

variable "admins_allowed_ips" {
  description = "Mapping of admin names to their allowed IPs"
  type        = map(string)
}
