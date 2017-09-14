param
(
    [Parameter(Mandatory=$true)] [string]  $Version,
    [Parameter(Mandatory=$true)] [boolean] $Primary,
    [Parameter(Mandatory=$true)] [boolean] $Secondary
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

$ravenResourceGroupName = "rg-sz-$locationCode-$deploymentCode-rvn"
$ravenLocation = (Get-AzureRmResourceGroup -Name $ravenResourceGroupName).Location

Write-Output "Updating Raven VM's..."

$vms = Get-AzureRmVM -ResourceGroupName $ravenResourceGroupName

$vms | foreach {

    $vm = $_
    $instanceNumber = $vm.Name.Substring($vm.Name.IndexOf("rvn") + 3)

    if ((($instanceNumber % 2) -eq 0 -and $Primary) -or (($instanceNumber % 2) -eq 1 -and $Secondary))
    {
        Write-Output "Updating $($vm.Name)..."

		$ext = Get-AzureRmVMCustomScriptExtension -Name 'Microsoft.Compute.CustomScriptExtension' -ResourceGroupName $ravenResourceGroupName -VMName $vm.Name -ErrorAction SilentlyContinue
		
		if ($ext.ProvisioningState -eq 'Failed')
		{
			Remove-AzureRmVMCustomScriptExtension -Name 'Microsoft.Compute.CustomScriptExtension' -ResourceGroupName $ravenResourceGroupName -VMName $vm.Name -Force | Out-Null
			Update-AzureRmVM -VM $vm -ResourceGroupName $ravenResourceGroupName | Out-Null
		}
		
		Set-AzureRmVMCustomScriptExtension -Name 'Microsoft.Compute.CustomScriptExtension' -ResourceGroupName $ravenResourceGroupName -VMName $vm.Name -Location $ravenLocation `
										   -FileUri 'https://github.com/criticalarc/sz-azure-deploy/raw/master/Scripts/Install-Raven.ps1' `
										   -Run "Install-Raven.ps1 -TeamCityUser ""$teamCityUser"" -TeamCityPass ""$teamCityPass"" -Version ""$Version""" -SecureExecution | Out-Null

		Update-AzureRmVM -VM $vm -ResourceGroupName $ravenResourceGroupName | Out-Null

        Write-Output "Updated $($vm.Name)."
    }
}

Write-Output "Update completed."
