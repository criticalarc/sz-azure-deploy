param (
    [object]$WebhookData
)

$ErrorActionPreference = 'Stop'

Import-Module AzureRM.Profile
Import-Module AzureRM.Automation

if ($WebhookData -ne $null)
{
    $connectionName = 'AzureRunAsConnection'

    try
    {
        $servicePrincipalConnection = Get-AutomationConnection -Name $connectionName        
    
        Write-Verbose "Logging in to Azure..."

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
        
    Write-Output "Body: $WebhookData.RequestBody"

    $webhookParams = ConvertFrom-Json -InputObject $WebhookData.RequestBody

    Write-Output "webhookParams: $webhookParams"

    $deploymentCode = Get-AutomationVariable -Name 'DeploymentCode'
    $locationCode = Get-AutomationVariable -Name 'LocationCode'
    $resourceGroupName = "rg-sz-$locationCode-$deploymentCode-auto"
    $automationAccountName = "aa-sz-$locationCode-$deploymentCode"

    switch ($webhookParams.Component)
    {
        "Raven" { $runbookParams = @{ Version = $webhookParams.Version; Primary = $webhookParams.Primary; Secondary = $webhookParams.Secondary; } }
        "Messaging" { $runbookParams = @{ Version = $webhookParams.Version; } }
        "Command" { $runbookParams = @{ Version = $webhookParams.Version; } }
        "Apps" { $runbookParams = @{ Version = $webhookParams.Version; } }
        "All" { $runbookParams = @{ Version = $webhookParams.Version; } }
        default { Write-Error "Invalid deployment component: $($webhookParams.Component)" }
    }

    $job = Start-AzureRmAutomationRunbook -ResourceGroupName $resourceGroupName -AutomationAccountName $automationAccountName -Name "Deploy-$($webhookParams.Component)" -Parameters $runbookParams

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
}
else
{
    Write-Error "This Runbook may only be started from a webhook."
}