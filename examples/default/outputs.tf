output "aci_name" {
  description = "The name assigned to the Azure Container Instance hosting SonarQube"
  value       = module.sonarqube.aci_name
}

output "appgw_fqdn" {
  description = "The fully qualified domain name (FQDN) of the Application Gateway public IP"
  value       = module.sonarqube.appgw_fqdn
}
