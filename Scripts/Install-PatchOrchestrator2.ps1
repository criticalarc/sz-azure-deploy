param (
	[string]$TempDirectory = "D:\Packages",
	[string]$POAUpdateTime = "04:00",
    [string]$POAUpdateFrequency = "Daily",
    [string]$POAApprovalPolicy = "NodeWise",
    [string]$POAWaitTimeBetweenNodes = "00:05:00",
	[Parameter(Mandatory)]
    [ValidatePattern("^latest$|^\d+\.\d+\.\d+$")]
    [string]$POAVersion,
    [Switch]$PatchNow
)

$ErrorActionPreference = 'Stop'

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Weird issue where this is _sometimes_ not in PATH
$sfPath = 'C:\Program Files\Microsoft Service Fabric\bin\Fabric\Fabric.Code'
if (!($env:Path -contains $sfPath))
{
    $env:Path = "$env:Path;$sfPath"
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
if ($PatchNow) {
    $POAUpdateTime = $((Get-Date).AddMinutes(30).ToString("HH:mm"))    
}

# Set POA Application Parameters
$POAParameters = @{
    WUFrequency = "$POAUpdateFrequency, $($POAUpdateTime)"
    TaskApprovalPolicy = "$POAApprovalPolicy"
    MinWaitTimeBetweenNodes = "$POAWaitTimeBetweenNodes"
}

# Check if POA version has been set. If not, use latest version.
if ($POAVersion -eq "latest") {
    $POARelease = ((Invoke-WebRequest "https://api.github.com/repos/microsoft/Service-Fabric-POA/releases/latest").Content | ConvertFrom-Json)
} else {
    $POARelease = ((Invoke-WebRequest "https://api.github.com/repos/microsoft/Service-Fabric-POA/releases").Content | ConvertFrom-Json | Where-Object {$_.tag_name -eq "v$($POAVersion)"})
}

$POAReleaseDownload = $POARelease.assets.browser_download_url | Where-Object {$_ -like "*.zip"}

if ($POAReleaseDownload) {
    # Download and unpack POA package from GitHub
    Invoke-WebRequest -Uri $POAReleaseDownload -OutFile "$TempDirectory\POA.zip"
    Expand-Archive "$TempDirectory\POA.zip" -DestinationPath "$TempDirectory\POA"
    Set-Location "$TempDirectory\POA"
    
    # Check for App and Install or Upgrade
    $PoaApp = Get-ServiceFabricApplication fabric:/PatchOrchestrationApplication
    if ($PoaApp) {
        if ($PoaApp.ApplicationTypeVersion -eq "$POAVersion") {
            # Upgrade POA settings
            Start-ServiceFabricApplicationUpgrade $PoaApp.ApplicationName -ApplicationTypeVersion $PoaApp.ApplicationTypeVersion -FailureAction Rollback -Monitored -ApplicationParameter $POAParameters
        } else {
            # Upgrade POA Package
            .\Upgrade.ps1 -ApplicationParameters $POAParameters
        }
    } else {
        # Deploy POA package
        .\Deploy.ps1 -ApplicationParameters $POAParameters
    }
} else {
    # Exit on error
    Write-Host "[ERROR] Failed to find Release for version $POAVersion" -ForegroundColor Red
    Exit 1
}
