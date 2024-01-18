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
$deploymentCode = Get-AutomationVariable -Name 'DeploymentCode'
$locationCode = Get-AutomationVariable -Name 'LocationCode'

$AzureContext = Set-AzContext -SubscriptionId "$SubscriptionId" -DefaultProfile $AzureContext

$NetworkNumber = switch ($DeploymentCode) {
    "d" { "0" }
    "t" { "10" }
    "p" {
        switch ($LocationCode) {
            "ae" { "20" }
            "uks" { "30" }
            "wus" { "40" }
        }
    }
}

$NsgReferences = Get-AzResource -Name "*-$deploymentCode-*-reference" -ResourceType Microsoft.Network/networkSecurityGroups

if ($NsgReferences) {
    foreach ($NsgReference in $NsgReferences) {
        $NsgReference = $NsgReference | Get-AzNetworkSecurityGroup

        $NsgTargetName = [regex]::Matches($NsgReference.Name, "(^\w.+)(-reference)").Groups[1].Value
        $NsgTargetName = $NsgTargetName -replace ("-ae-","-$locationCode-")
        $NsgTarget = Get-AzNetworkSecurityGroup -Name $NsgTargetName

        if ($NsgTarget) {
            $NsgRules=@()

            $NsgReference.SecurityRules | ForEach-Object {
                $NsgRules += New-AzNetworkSecurityRuleConfig -Name $_.Name `
                    -Protocol $_.Protocol `
                    -SourcePortRange $_.SourcePortRange `
                    -DestinationPortRange $_.DestinationPortRange `
                    -SourceAddressPrefix $_.SourceAddressPrefix `
                    -DestinationAddressPrefix ($_.DestinationAddressPrefix -replace ("20","$NetworkNumber")) `
                    -SourceApplicationSecurityGroup $_.SourceApplicationSecurityGroup `
                    -DestinationApplicationSecurityGroup $_.DestinationApplicationSecurityGroup `
                    -Access $_.Access `
                    -Priority $_.Priority `
                    -Direction $_.Direction
            }

            $NsgTarget.SecurityRules = $NsgRules

            Write-Output "Resetting security rules in '$($NsgTarget.Name)' using '$($NsgReference.Name)' as reference."
            $NsgTarget | Set-AzNetworkSecurityGroup | Select-Object -ExpandProperty SecurityRules | Format-Table

        } else {
            Write-Output "NSG '$NsgTargetName' not found in Azure subscription '$($AzureContext.Subscription.Name)'. Security rules from NSG '$($NsgReference.Name)' not applied."
        }
    }
} else {
    Write-Output "No reference NSGs found in Azure subscription '$($AzureContext.Subscription.Name)'"
}
