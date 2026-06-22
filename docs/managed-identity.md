# Managed Identity and Key Vault

This project uses `DefaultAzureCredential` in `Program.cs`. In Azure Functions, that credential can authenticate with the Function App's system-assigned managed identity after the identity is enabled and granted access to Key Vault.

## Configure Azure

Run the script after the Function App and Key Vault already exist:

```powershell
.\scripts\configure-managed-identity.ps1 `
  -FunctionAppName "<function-app-name>" `
  -ResourceGroupName "<resource-group-name>" `
  -KeyVaultName "<key-vault-name>"
```

If you need to target a specific subscription:

```powershell
.\scripts\configure-managed-identity.ps1 `
  -SubscriptionId "<subscription-id>" `
  -FunctionAppName "<function-app-name>" `
  -ResourceGroupName "<resource-group-name>" `
  -KeyVaultName "<key-vault-name>"
```

The script enables the Function App system-assigned identity, reads the resulting service principal object id, then grants Key Vault secret access.

By default, it auto-detects the Key Vault permission model:

- RBAC-enabled vaults receive the `Key Vault Secrets User` role at the vault scope.
- Access-policy vaults receive `get` and `list` secret permissions.

You can force either mode:

```powershell
.\scripts\configure-managed-identity.ps1 `
  -FunctionAppName "<function-app-name>" `
  -ResourceGroupName "<resource-group-name>" `
  -KeyVaultName "<key-vault-name>" `
  -PermissionMode Rbac
```

## Verify

Check that the Function App has a principal id:

```powershell
az functionapp identity show `
  --name "<function-app-name>" `
  --resource-group "<resource-group-name>"
```

For RBAC vaults, check role assignments:

```powershell
$keyVaultScope = az keyvault show --name "<key-vault-name>" --query id -o tsv
az role assignment list `
  --assignee "<principal-id>" `
  --scope $keyVaultScope
```

For access-policy vaults, check policies:

```powershell
az keyvault show `
  --name "<key-vault-name>" `
  --query "properties.accessPolicies[?objectId=='<principal-id>']"
```
