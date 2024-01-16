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

$SubscriptionId = Get-AutomationVariable -Name 'SubscriptionId'
$AzureContext = Set-AzContext -SubscriptionId "$SubscriptionId" -DefaultProfile $AzureContext

$NsgReferences = Get-AzResource -Name "*-reference" -ResourceType Microsoft.Network/networkSecurityGroups

if ($NsgReferences) {
    foreach ($NsgReference in $NsgReferences) {
        $NsgReference = $NsgReference | Get-AzNetworkSecurityGroup

        $NsgTargetName = [regex]::Matches($NsgReference.Name, "(^\w.+)(-reference)").Groups[1].Value
        $NsgTarget = Get-AzNetworkSecurityGroup -Name $NsgTargetName

        if ($NsgTarget) {
            $NsgTarget.SecurityRules = $NsgReference.SecurityRules

            Write-Host "Resetting security rules in '$($NsgTarget.Name)' using '$($NsgReference.Name)' as reference."
        
            $NsgTarget | Set-AzNetworkSecurityGroup | Select-Object -ExpandProperty SecurityRules | Format-Table
        } else {
            Write-Output "NSG '$NsgTargetName' not found in Azure subscription '$($AzureContext.Subscription.Name)'. Security rules from NSG '$($NsgReference.Name)' not applied."
        }
    }
} else {
    Write-Output "No reference NSGs found in Azure subscription '$($AzureContext.Subscription.Name)'"
}
