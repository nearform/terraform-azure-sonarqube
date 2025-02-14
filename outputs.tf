output "appgw_fqdn" {
  description = "The fully qualified domain name (FQDN) of the Application Gateway public IP."
  value       = azurerm_public_ip.appgw.fqdn
}
