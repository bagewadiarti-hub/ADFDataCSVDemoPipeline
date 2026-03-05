output "resource_group" { value = azurerm_resource_group.rg.name }
output "data_factory_name" { value = azurerm_data_factory.adf.name }
output "storage_account_name" { value = azurerm_storage_account.storage.name }
output "input_container_name" { value = azurerm_storage_container.input_container.name }
output "output_container_name" { value = azurerm_storage_container.output_container.name }
