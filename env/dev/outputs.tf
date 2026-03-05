output "resource_group" {
  value = azurerm_resource_group.rg.name
}

output "data_factory_name" {
  value = azurerm_data_factory.adf.name
}
