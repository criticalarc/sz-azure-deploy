param
(
    [Parameter(Mandatory = $true)] [string] $TeamCityUser,
    [Parameter(Mandatory = $true)] [string] $TeamCityPass,
    [Parameter(Mandatory = $true)] [string] $LocationCode,
    [Parameter(Mandatory = $true)] [string] $DeploymentCode,
    [Parameter(Mandatory = $true)] [string] $Version
)

$ErrorActionPreference = 'Stop'

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

$localNodeName = (Get-ServiceFabricClusterConnection).GatewayInformation.NodeName
$firstNodeName = (Get-ServiceFabricNode | sort -Property NodeName | select -First 1).NodeName

if ($localNodeName -ne $firstNodeName)
{
    return;
}

$packageDir = 'D:\Packages'
$params = "sz-$LocationCode-$DeploymentCode.xml"

md -Path $packageDir -ErrorAction Ignore

$username = $TeamCityUser
$password = $TeamCityPass | ConvertTo-SecureString -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential($username, $password)

[xml]$metadata = iwr -Credential $credential -UseBasicParsing "https://teamcity.criticalarc.net/httpAuth/app/nuget/v1/FeedService.svc/Packages(Id='safezone-azure-messaging',Version='$Version')"
$url = $metadata.entry.content.src -replace 'http://', 'https://'
$packagePath = "$packageDir\safezone-azure-messaging.$Version.nupkg"
$oldPackages = Get-Item -Path "$packageDir\safezone-azure-messaging.*" -Exclude "safezone-azure-messaging.$Version.nupkg"
iwr -Credential $credential -UseBasicParsing -OutFile $packagePath $url

$action = 'install'
$installedPackage = C:\choco\choco list -lo | Where-object { $_.ToLower().Contains('safezone-azure-messaging') }
$install = $true

if ($installedPackage.Count -gt 0)
{
    $action = 'upgrade'
    $nameVersion = $installedPackage -split ' '

    if ($nameVersion[1] -eq $Version)
    {
        $install = $false
    }
}

if ($install)
{
    C:\choco\choco $action safezone-azure-messaging -s "'$packageDir'" -u "'$TeamCityUser'" -p "'$TeamCityPass'" --version "'$Version'" --params "'$params'" --confirm --pre --allow-downgrade --timeout 3600

    if (!$?)
    {
        Write-Error "Failed to install package safezone-azure-messaging"
    }

    $oldPackages | Remove-Item -Force
}

[xml]$metadata = iwr -Credential $credential -UseBasicParsing "https://teamcity.criticalarc.net/httpAuth/app/nuget/v1/FeedService.svc/Packages(Id='safezone-azure-command',Version='$Version')"
$url = $metadata.entry.content.src -replace 'http://', 'https://'
$packagePath = "$packageDir\safezone-azure-command.$Version.nupkg"
$oldPackages = Get-Item -Path "$packageDir\safezone-azure-command.*" -Exclude "safezone-azure-command.$Version.nupkg"
iwr -Credential $credential -UseBasicParsing -OutFile $packagePath $url

$action = 'install'
$installedPackage = C:\choco\choco list -lo | Where-object { $_.ToLower().Contains('safezone-azure-command') }
$install = $true

if ($installedPackage.Count -gt 0)
{
    $action = 'upgrade'
    $nameVersion = $installedPackage -split ' '

    if ($nameVersion[1] -eq $Version)
    {
        $install = $false
    }
}

if ($install)
{
    C:\choco\choco $action safezone-azure-command -s "'$packageDir'" --version "'$Version'" --params "'$params'" --confirm --pre --allow-downgrade --timeout 3600

    if (!$?)
    {
        Write-Error "Failed to install package safezone-azure-command"
    }

    $oldPackages | Remove-Item -Force
}
