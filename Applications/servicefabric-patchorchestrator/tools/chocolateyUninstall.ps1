#requires -version 3.0

$ErrorActionPreference        = "Stop"

$toolsDir                     = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$applicationName              = "fabric:/PatchOrchestratorApplication"

Import-Module $toolsDir\ServiceFabricSDK

try
{
    [void](Test-ServiceFabricClusterConnection)
}
catch
{
    Connect-ServiceFabricCluster
}

Unpublish-ServiceFabricApplication -ApplicationName $applicationName
