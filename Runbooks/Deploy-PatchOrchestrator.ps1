param
(
    [string]$Version = "latest"
)

$ErrorActionPreference = 'Stop'

try
{
    Write-Output "Logging in to Azure..."

    # Ensures you do not inherit an Azure Context in runbook
    Disable-AzContextAutosave -Scope Process

    # Connect to Azure with system-assigned managed identity
    $AzureContext = (Connect-AzAccount -Identity).context
}
catch
{
    Write-Error -Message $_.Exception
    throw $_.Exception
}

if (!($AzureContext.Subscription)) {
    Write-Error -Message "Managed identity does not have access to any subscriptions"
}

$subscriptionId = Get-AutomationVariable -Name 'SubscriptionId'
$deploymentCode = Get-AutomationVariable -Name 'DeploymentCode'
$locationCode = Get-AutomationVariable -Name 'LocationCode'

$AzureContext = Set-AzContext -SubscriptionId "$subscriptionId" -DefaultProfile $AzureContext

$appsResourceGroupName = "rg-sz-$locationCode-$deploymentCode-app"
$appsVMScaleSetName = "vmsssz$($locationCode)$($deploymentCode)app"

Write-Output "Updating Apps VM Scale Set with Patch Orchestrator..."

$vmss = Get-AzVmss -ResourceGroupName $appsResourceGroupName -VMScaleSetName $appsVMScaleSetName
$fileUris = @('https://raw.githubusercontent.com/criticalarc/sz-azure-deploy/bg/ITO-125-Patch-Orchestrator-Runbook/Scripts/Install-PatchOrchestrator.ps1')
$setting = @{fileUris=$fileUris}
$protectedSetting = @{commandToExecute="powershell -ExecutionPolicy Unrestricted -File Install-PatchOrchestrator.ps1 -POAVersion ""$Version"""}

$customScriptExtension = $vmss.VirtualMachineProfile.ExtensionProfile.Extensions | where {$_.Name -eq "Microsoft.Compute.CustomScriptExtension"}

if ($customScriptExtension.Count -gt 0)
{
	$customScriptExtension[0].TypeHandlerVersion = '1.10'
	$customScriptExtension[0].AutoUpgradeMinorVersion = $true
	$customScriptExtension[0].Settings = $setting
	$customScriptExtension[0].ProtectedSettings = $protectedSetting
	$customScriptExtension[0].ForceUpdateTag = (Get-Date -Format "O")
}
else
{
	Add-AzVmssExtension -VirtualMachineScaleSet $vmss -Name 'Microsoft.Compute.CustomScriptExtension' `
							 -Publisher 'Microsoft.Compute' -Type 'CustomScriptExtension' -TypeHandlerVersion '1.10' -AutoUpgradeMinorVersion $true `
							 -Setting $setting -ProtectedSetting $protectedSetting | Out-Null
}

Update-AzVmss -ResourceGroupName $appsResourceGroupName -VirtualMachineScaleSet $vmss -Name $appsVMScaleSetName | Out-Null
    
Write-Output "Update completed."
