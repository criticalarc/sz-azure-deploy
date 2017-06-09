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

if ($application)
{
    Publish-UpgradedServiceFabricApplication -ApplicationPackagePath $applicationPackagePath -UnregisterUnusedVersions
}
else
{
    Publish-NewServiceFabricApplication -ApplicationPackagePath $applicationPackagePath
}
