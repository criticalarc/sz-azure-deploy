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

Set-AzureRmContext -SubscriptionId $subscriptionId | Out-Null

$appsResourceGroupName = "rg-sz-$locationCode-$deploymentCode-app"
$appsVMScaleSetName = "vmsssz$($locationCode)$($deploymentCode)app"

Write-Output "Updating Apps VM Scale Set with Patch Orchestrator..."

$vmss = Get-AzureRmVmss -ResourceGroupName $appsResourceGroupName -VMScaleSetName $appsVMScaleSetName
$fileUris = @('https://raw.githubusercontent.com/criticalarc/sz-azure-deploy/master/Scripts/Install-PatchOrchestrator.ps1')
$setting = @{fileUris=$fileUris}
$protectedSetting = @{commandToExecute="powershell -ExecutionPolicy Unrestricted -File Install-PatchOrchestrator.ps1 -Version ""$Version"""}

if (($vmss.VirtualMachineProfile.ExtensionProfile.Extensions | where {$_.Name -eq "Microsoft.Compute.CustomScriptExtension"}).Count -gt 0)
{
    Remove-AzureRmVmssExtension -VirtualMachineScaleSet $vmss -Name 'Microsoft.Compute.CustomScriptExtension' | Out-Null
    Update-AzureRmVmss -ResourceGroupName $appsResourceGroupName -VirtualMachineScaleSet $vmss -Name $appsVMScaleSetName | Out-Null
}

Add-AzureRmVmssExtension -VirtualMachineScaleSet $vmss -Name 'Microsoft.Compute.CustomScriptExtension' `
                         -Publisher 'Microsoft.Compute' -Type 'CustomScriptExtension' -TypeHandlerVersion '1.9' -AutoUpgradeMinorVersion $true `
                         -Setting $setting -ProtectedSetting $protectedSetting | Out-Null

Update-AzureRmVmss -ResourceGroupName $appsResourceGroupName -VirtualMachineScaleSet $vmss -Name $appsVMScaleSetName | Out-Null
    
Write-Output "Update completed."
