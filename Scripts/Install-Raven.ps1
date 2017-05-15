param
(
    [Parameter(Mandatory = $true)] [string] $TeamCityUser,
    [Parameter(Mandatory = $true)] [string] $TeamCityPass,
    [Parameter(Mandatory = $true)] [string] $Version
)

$ErrorActionPreference = 'Stop'

$packageDir = 'D:\Packages'

md -Path $packageDir -ErrorAction Ignore

$username = $TeamCityUser
$password = $TeamCityPass | ConvertTo-SecureString -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential($username, $password)

[xml]$metadata = iwr -Credential $credential -UseBasicParsing "https://teamcity.criticalarc.net/httpAuth/app/nuget/v1/FeedService.svc/Packages(Id='safezone-azure-raven-maintenance',Version='$Version')"
$url = $metadata.entry.content.src -replace 'http://', 'https://'
$packagePath = "$packageDir\safezone-azure-raven-maintenance.$Version.nupkg"
$oldPackages = Get-Item -Path "$packageDir\safezone-azure-raven-maintenance.*" -Exclude "safezone-azure-raven-maintenance.$Version.nupkg"
iwr -Credential $credential -UseBasicParsing -OutFile $packagePath $url

$action = 'install'
$installedPackage = C:\choco\choco list -lo | Where-object { $_.ToLower().Contains('safezone-azure-raven-maintenance') }
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
    C:\choco\choco $action safezone-azure-raven-maintenance -s "'$packageDir'" -u "'$TeamCityUser'" -p "'$TeamCityPass'" --version "'$Version'" --confirm --pre --allow-downgrade --timeout 300

    if (!$?)
    {
        Write-Error "Failed to install package safezone-azure-raven-maintenance"
    }

    $oldPackages | Remove-Item -Force
}

[xml]$metadata = iwr -Credential $credential -UseBasicParsing "https://teamcity.criticalarc.net/httpAuth/app/nuget/v1/FeedService.svc/Packages(Id='safezone-azure-raven-server',Version='$Version')"
$url = $metadata.entry.content.src -replace 'http://', 'https://'
$packagePath = "$packageDir\safezone-azure-raven-server.$Version.nupkg"
$oldPackages = Get-Item -Path "$packageDir\safezone-azure-raven-server.*" -Exclude "safezone-azure-raven-server.$Version.nupkg"
iwr -Credential $credential -UseBasicParsing -OutFile $packagePath $url

$action = 'install'
$installedPackage = C:\choco\choco list -lo | Where-object { $_.ToLower().Contains('safezone-azure-raven-server') }
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
    C:\choco\choco $action safezone-azure-raven-server -s "'$packageDir'" -u "'$TeamCityUser'" -p "'$TeamCityPass'" --version "'$Version'" --confirm --pre --allow-downgrade --timeout 3600

    if (!$?)
    {
        Write-Error "Failed to install package safezone-azure-raven-server"
    }

    $oldPackages | Remove-Item -Force
}
