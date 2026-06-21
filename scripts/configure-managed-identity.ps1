param(
    [Parameter(Mandatory = $true)]
    [string]$FunctionAppName,

    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName,

    [Parameter(Mandatory = $true)]
    [string]$KeyVaultName,

    [string]$SubscriptionId,

    [ValidateSet("Auto", "Rbac", "AccessPolicy")]
    [string]$PermissionMode = "Auto",

    [string]$KeyVaultRoleName = "Key Vault Secrets User"
)

$ErrorActionPreference = "Stop"

if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
    throw "Azure CLI is required. Install it from https://learn.microsoft.com/cli/azure/install-azure-cli and run 'az login'."
}

if ($SubscriptionId) {
    az account set --subscription $SubscriptionId | Out-Null
}

Write-Host "Enabling system-assigned managed identity on Function App '$FunctionAppName'..."
$identity = az functionapp identity assign `
    --name $FunctionAppName `
    --resource-group $ResourceGroupName `
    --output json | ConvertFrom-Json

$principalId = $identity.principalId

if (-not $principalId) {
    $identity = az functionapp identity show `
        --name $FunctionAppName `
        --resource-group $ResourceGroupName `
        --output json | ConvertFrom-Json
    $principalId = $identity.principalId
}

if (-not $principalId) {
    throw "The Function App identity was not returned by Azure CLI."
}

$vault = az keyvault show --name $KeyVaultName --output json | ConvertFrom-Json
$useRbac = $PermissionMode -eq "Rbac" -or ($PermissionMode -eq "Auto" -and $vault.properties.enableRbacAuthorization)

if ($useRbac) {
    Write-Host "Granting '$KeyVaultRoleName' on Key Vault '$KeyVaultName' to managed identity '$principalId'..."
    az role assignment create `
        --assignee-object-id $principalId `
        --assignee-principal-type ServicePrincipal `
        --role $KeyVaultRoleName `
        --scope $vault.id | Out-Null
}
else {
    Write-Host "Granting Key Vault secret get/list permissions on '$KeyVaultName' to managed identity '$principalId'..."
    az keyvault set-policy `
        --name $KeyVaultName `
        --object-id $principalId `
        --secret-permissions get list | Out-Null
}

Write-Host "Managed identity configured."
Write-Host "PrincipalId: $principalId"
Write-Host "KeyVault: $KeyVaultName"
