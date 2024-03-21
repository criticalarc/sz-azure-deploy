param (
    [string]$TempDirectory = "D:\Packages",
    [string]$PoaUpdateTime = "04:00",
    [string]$PoaUpdateFrequency = "Daily",
    [string]$PoaApprovalPolicy = "NodeWise",
    [string]$PoaWaitTimeBetweenNodes = "00:05:00",
    [string[]]$SkipUpdateIds = "a8a2d6e3-c6dc-4eb8-bcfb-8c8c7d947899",
    [ValidatePattern("^latest$|^\d+\.\d+\.\d+$")][string]$PoaVersion = "1.5.1",
    [ValidateSet("criticalarc","microsoft")][string]$RepoOwner = "criticalarc",
    [string]$PatchNow
)

$ErrorActionPreference = 'Stop'

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Weird issue where this is _sometimes_ not in PATH
$sfPath = 'C:\Program Files\Microsoft Service Fabric\bin\Fabric\Fabric.Code'
if (!($env:Path -contains $sfPath))
{
    $env:Path = "$env:Path;$sfPath"
}

if (!(Test-Path $TempDirectory)) {
    New-Item $TempDirectory -ItemType Directory
}

try
{
    [void](Test-ServiceFabricClusterConnection)
}
catch
{
    Connect-ServiceFabricCluster
}

# If Patching is required now, update time will be set to current time + 30 minutes to allow VMSS host config then execute
if ($PatchNow -eq "true") {
    $PoaUpdateTime = $((Get-Date).AddMinutes(15).ToString("HH:mm"))    
}

# Set POA Application Parameters
$PoaParameters = @{
    WUFrequency = "$PoaUpdateFrequency, $($PoaUpdateTime)"
    TaskApprovalPolicy = "$PoaApprovalPolicy"
    MinWaitTimeBetweenNodes = "$PoaWaitTimeBetweenNodes"
    SkipUpdateIds = "$SkipUpdateIds"
}

# Check if POA version has been set. If not, use latest version.
if ($PoaVersion -eq "latest") {
    $PoaRelease = (Invoke-RestMethod "https://api.github.com/repos/$RepoOwner/Service-Fabric-POA/releases/latest" -UseBasicParsing)
} else {
    $PoaRelease = (Invoke-RestMethod "https://api.github.com/repos/$RepoOwner/Service-Fabric-POA/releases" -UseBasicParsing) | Where-Object {$_.tag_name -eq "v$($PoaVersion)"}
}

$PoaVersion = $PoaRelease.tag_name -replace ("v","")
$PoaReleaseDownload = $PoaRelease.assets.browser_download_url | Where-Object {$_ -like "*.zip"}

if ($PoaReleaseDownload) {
    # Download and unpack POA package from GitHub
    Invoke-RestMethod -Uri $PoaReleaseDownload -UseBasicParsing -OutFile "$TempDirectory\POA.zip"
    Expand-Archive "$TempDirectory\POA.zip" -DestinationPath "$TempDirectory\POA" -Force
    Set-Location "$TempDirectory\POA"
    
    # Check for App and Install or Upgrade
    $PoaApp = Get-ServiceFabricApplication fabric:/PatchOrchestrationApplication
    if ($PoaApp) {
        $PoaAppUpgradeStatus = Get-ServiceFabricApplicationUpgrade -ApplicationName fabric:/PatchOrchestrationApplication
        if ($PoaAppUpgradeStatus.UpgradeDomainsStatus -and $PoaAppUpgradeStatus.UpgradeDomainsStatus.State -notmatch "Completed") {
            Write-Output "POA application install already in progress"
            Exit 0
        } else {
            if ($PoaApp.ApplicationTypeVersion -eq "$PoaVersion") {
                # Upgrade POA settings
                Start-ServiceFabricApplicationUpgrade $PoaApp.ApplicationName -ApplicationTypeVersion $PoaApp.ApplicationTypeVersion -FailureAction Rollback -Monitored -ApplicationParameter $PoaParameters
            } else {
                # Upgrade POA Package
                .\Upgrade.ps1 -ApplicationParameters $PoaParameters -ApplicationVersion $PoaVersion
            }
        }
    } else {
        # Deploy POA package
        .\Deploy.ps1 -ApplicationParameters $PoaParameters
    }
} else {
    # Exit on error
    Write-Host "[ERROR] Failed to find Release for version $PoaVersion" -ForegroundColor Red
    Exit 1
}
