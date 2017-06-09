param
(
    [Parameter(Mandatory=$true)] [string] $Version
)

$ErrorActionPreference = 'Stop'

Import-Module AzureRM.Profile

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

$deploymentCode = Get-AutomationVariable -Name 'DeploymentCode'
$locationCode = Get-AutomationVariable -Name 'LocationCode'
$resourceGroupName = "rg-sz-$locationCode-$deploymentCode-auto"
$automationAccountName = "aa-sz-$locationCode-$deploymentCode"

Write-Output "Deploying Raven Primary"

$runbookParams = @{ Version = $Version; Primary = $true; Secondary = $false; }
$job = Start-AzureRmAutomationRunbook -ResourceGroupName $resourceGroupName -AutomationAccountName $automationAccountName -Name "Deploy-Raven" -Parameters $runbookParams

while ($job.Status -ne "Completed" -and $job.Status -ne "Stopped" -and $job.Status -ne "Failed")
{
    sleep 1
    $job = Get-AzureRmAutomationJob -Id $job.JobId -ResourceGroupName $resourceGroupName -AutomationAccountName $automationAccountName
}

if ($job.Status -eq "Failed")
{
    Write-Error -Message $job.Exception
    throw $job.Exception
}

Write-Output "Deploying Apps"

$runbookParams = @{ Version = $Version; }
$job = Start-AzureRmAutomationRunbook -ResourceGroupName $resourceGroupName -AutomationAccountName $automationAccountName -Name "Deploy-Apps" -Parameters $runbookParams

while ($job.Status -ne "Completed" -and $job.Status -ne "Stopped" -and $job.Status -ne "Failed")
{
    sleep 1
    $job = Get-AzureRmAutomationJob -Id $job.JobId -ResourceGroupName $resourceGroupName -AutomationAccountName $automationAccountName
}

if ($job.Status -eq "Failed")
{
    Write-Error -Message $job.Exception
    throw $job.Exception
}

Write-Output "Deploying Raven Secondary"

$runbookParams = @{ Version = $Version; Primary = $false; Secondary = $true; }
$job = Start-AzureRmAutomationRunbook -ResourceGroupName $resourceGroupName -AutomationAccountName $automationAccountName -Name "Deploy-Raven" -Parameters $runbookParams

while ($job.Status -ne "Completed" -and $job.Status -ne "Stopped" -and $job.Status -ne "Failed")
{
    sleep 1
    $job = Get-AzureRmAutomationJob -Id $job.JobId -ResourceGroupName $resourceGroupName -AutomationAccountName $automationAccountName
}

if ($job.Status -eq "Failed")
{
    Write-Error -Message $job.Exception
    throw $job.Exception
}
