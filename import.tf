import {
  # Only import in ithc, where the secret exists in the vault but not in state
  for_each = var.env == "ithc" ? toset(["import"]) : toset([])
  to       = azurerm_key_vault_secret.MaxFileUploadRequestSizeInMegabytes
  id       = "https://darts-${var.env}.vault.azure.net/secrets/MaxFileUploadRequestSizeInMegabytes/dfcd980b570c4853a84be85dd3577274"
}
