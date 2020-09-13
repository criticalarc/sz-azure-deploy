param
(
    [Parameter(Mandatory=$true)] [string] $Version
)

$ErrorActionPreference = 'Stop'

Import-Module AzureRM.Profile
Import-Module AzureRM.Compute

$connectionName = 'AzureRunAsConnection'

try
{
    $servicePrincipalConnection = Get-AutomationConnection -Name $connectionName        
 
    Write-Output "Logging in to Azure..."

    Add-AzureRmAccount `
        -ServicePrincipal `
        -TenantId $servicePrincipalConnection.TenantId `
        -ApplicationId $servicePrincipalConnection.ApplicationId `
        -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint | Out-Null
}
catch
{
    if (!$servicePrincipalConnection)
    {
        $ErrorMessage = "Connection $connectionName not found."
        throw $ErrorMessage
    }
    else
    {
        Write-Error -Message $_.Exception
        throw $_.Exception
    }
}

$subscriptionId = Get-AutomationVariable -Name 'SubscriptionId'
$deploymentCode = Get-AutomationVariable -Name 'DeploymentCode'
$locationCode = Get-AutomationVariable -Name 'LocationCode'
$teamCityCredentials = Get-AutomationPSCredential -Name 'TeamCity'
$teamCityUser = $teamCityCredentials.GetNetworkCredential().UserName
$teamCityPass = $teamCityCredentials.GetNetworkCredential().Password

Set-AzureRmContext -SubscriptionId $subscriptionId | Out-Null

$appsResourceGroupName = "rg-sz-$locationCode-$deploymentCode-app"
$appsVMScaleSetName = "vmsssz$($locationCode)$($deploymentCode)app"

Write-Output "Updating Command VM Scale Set..."

$vmss = Get-AzureRmVmss -ResourceGroupName $appsResourceGroupName -VMScaleSetName $appsVMScaleSetName
$fileUris = @('https://raw.githubusercontent.com/criticalarc/sz-azure-deploy/master/Scripts/Install-Command.ps1')
$setting = @{fileUris=$fileUris}
$protectedSetting = @{commandToExecute="powershell -ExecutionPolicy Unrestricted -File Install-Command.ps1 -TeamCityUser ""$teamCityUser"" -TeamCityPass ""$teamCityPass"" -Version ""$Version"" -LocationCode ""$locationCode"" -DeploymentCode ""$deploymentCode"""}

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
	Add-AzureRmVmssExtension -VirtualMachineScaleSet $vmss -Name 'Microsoft.Compute.CustomScriptExtension' `
							 -Publisher 'Microsoft.Compute' -Type 'CustomScriptExtension' -TypeHandlerVersion '1.10' -AutoUpgradeMinorVersion $true `
							 -Setting $setting -ProtectedSetting $protectedSetting | Out-Null
}

Update-AzureRmVmss -ResourceGroupName $appsResourceGroupName -VirtualMachineScaleSet $vmss -Name $appsVMScaleSetName | Out-Null

Write-Output "Update completed."
