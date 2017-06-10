#requires -version 3.0

$ErrorActionPreference = "Stop"

$toolsDir                     = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$applicationName              = "fabric:/PatchOrchestratorApplication"
$applicationPackagePath       = Join-Path $toolsDir 'servicefabric-patchorchestrator.sfpkg'

Import-Module $toolsDir\ServiceFabricSDK

try
{
    [void](Test-ServiceFabricClusterConnection)
}
catch
{
    Connect-ServiceFabricCluster
}

$application = Get-ServiceFabricApplication -ApplicationName $applicationName -ErrorAction Ignore
$parameters = @{
    WUFrequency = 'Daily, 04:00'
    TaskApprovalPolicy = 'NodeWise'
}

if ($application)
{
    Publish-UpgradedServiceFabricApplication -ApplicationPackagePath $applicationPackagePath -ApplicationName $applicationName -ApplicationParameter $parameters -UnregisterUnusedVersions
}
else
{
    Publish-NewServiceFabricApplication -ApplicationPackagePath $applicationPackagePath -ApplicationName $applicationName -ApplicationParameter $parameters
}
