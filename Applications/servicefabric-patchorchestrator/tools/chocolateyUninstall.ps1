#requires -version 3.0

Import-Module .\ServiceFabricSDK

$ErrorActionPreference = "Stop"

$applicationName              = "fabric:/PatchOrchestratorApplication"

Connect-ServiceFabricCluster

Unpublish-ServiceFabricApplication -ApplicationName $applicationName
