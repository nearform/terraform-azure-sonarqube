output "aci_id" {
  description = "The ID of the Azure Container Instance hosting SonarQube"
  value       = azurerm_container_group.sonarqube.id
}

output "aci_name" {
  description = "The name assigned to the Azure Container Instance hosting SonarQube"
  value       = azurerm_container_group.sonarqube.name
}

output "appgw_id" {
  description = "The ID of the Application Gateway managing SonarQube traffic"
  value       = azurerm_public_ip.appgw.id
}

output "appgw_fqdn" {
  description = "The fully qualified domain name (FQDN) of the Application Gateway public IP"
  value       = azurerm_public_ip.appgw.fqdn
}
