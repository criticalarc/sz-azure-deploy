param
(
    [Parameter(Mandatory = $true)] [string] $Version
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

$localNodeName = (Get-ServiceFabricClusterConnection).GatewayInformation.NodeName
$firstNodeName = (Get-ServiceFabricNode | sort -Property NodeName | select -First 1).NodeName

if ($localNodeName -ne $firstNodeName)
{
    return;
}

$packageDir = 'D:\Packages'

md -Path $packageDir -ErrorAction Ignore

$url = "https://raw.githubusercontent.com/criticalarc/sz-azure-deploy/master/Applications/servicefabric-patchorchestrator.$Version.nupkg"
$packagePath = "$packageDir\servicefabric-patchorchestrator.$Version.nupkg"
$oldPackages = Get-Item -Path "$packageDir\servicefabric-patchorchestrator.*" -Exclude "servicefabric-patchorchestrator.$Version.nupkg"
iwr -UseBasicParsing -OutFile $packagePath $url

$action = 'install'
$installedPackage = C:\choco\choco list -lo | Where-object { $_.ToLower().Contains('servicefabric-patchorchestrator') }
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
    C:\choco\choco $action servicefabric-patchorchestrator -s "'$packageDir'" --version "'$Version'" --confirm --pre --allow-downgrade --timeout 3600

    if (!$?)
    {
        Write-Error "Failed to install package servicefabric-patchorchestrator"
    }

    $oldPackages | Remove-Item -Force
}
