function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Path,

        [parameter(Mandatory = $true)]
        [System.String]
        $Subject,
        
        [parameter(Mandatory = $true)]
        [System.String]
        $Identity,

        [parameter(Mandatory = $true)]
        [System.Security.AccessControl.FileSystemRights]
        $Rights,

        [parameter(Mandatory = $true)]
        [System.Security.AccessControl.AccessControlType]
        $Access
    )
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Path,

        [parameter(Mandatory = $true)]
        [System.String]
        $Subject,
        
        [parameter(Mandatory = $true)]
        [System.String]
        $Identity,

        [parameter(Mandatory = $true)]
        [System.Security.AccessControl.FileSystemRights]
        $Rights,

        [parameter(Mandatory = $true)]
        [System.Security.AccessControl.AccessControlType]
        $Access
    )

    $certificates = Get-ChildItem $Path | Where { $_.Subject -like $Subject }

    if ($certificates -eq $null -or $certificates.Length -eq 0)
    {
        if ($DnsName)
        {
            Write-Error "No certificates at path '$Path' with DnsName '$DnsName'."
        }
        else
        {
            Write-Error "No certificates at path '$Path'."
        }

        return
    }

    $permission = $Identity,$Rights,$Access
    $accessRule = New-Object -TypeName System.Security.AccessControl.FileSystemAccessRule -ArgumentList $permission
    
    foreach ($certificate in $certificates)
    {
        $keyPath = $env:ProgramData + "\Microsoft\Crypto\RSA\MachineKeys\"
        $keyName = $certificate.PrivateKey.CspKeyContainerInfo.UniqueKeyContainerName
        $keyFullPath = Join-Path $keyPath $keyName
        $acl = Get-Acl -Path $keyFullPath
        $acl.AddAccessRule($accessRule)
        Set-Acl -Path $keyFullPath -AclObject $acl
    }
}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Path,

        [parameter(Mandatory = $true)]
        [System.String]
        $Subject,
        
        [parameter(Mandatory = $true)]
        [System.String]
        $Identity,

        [parameter(Mandatory = $true)]
        [System.Security.AccessControl.FileSystemRights]
        $Rights,

        [parameter(Mandatory = $true)]
        [System.Security.AccessControl.AccessControlType]
        $Access
    )

    $certificates = Get-ChildItem $Path | Where { $_.Subject -like $Subject }
    
    if ($certificates -eq $null -or $certificates.Length -eq 0)
    {
        return $false
    }
    
    foreach ($certificate in $certificates)
    {
        $keyPath = $env:ProgramData + "\Microsoft\Crypto\RSA\MachineKeys\"
        $keyName = $certificate.PrivateKey.CspKeyContainerInfo.UniqueKeyContainerName
        $keyFullPath = Join-Path $keyPath $keyName
        $acl = Get-Acl -Path $keyFullPath
        $item = $acl.Access | where { $_.IdentityReference -eq $Identity -and $_.FileSystemRights.HasFlag($Rights) -and $_.AccessControlType -eq $Access }
        
        if ($item -eq $null)
        {
            return $false
        }
    }
    
    $true
}


Export-ModuleMember -Function *-TargetResource

