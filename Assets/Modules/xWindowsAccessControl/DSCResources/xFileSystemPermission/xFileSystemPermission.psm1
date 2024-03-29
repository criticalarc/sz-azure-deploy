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
        $Identity,

        [parameter(Mandatory = $true)]
        [System.Security.AccessControl.FileSystemRights]
        $Rights,

        [parameter(Mandatory = $true)]
        [System.Security.AccessControl.AccessControlType]
        $Access
    )

    $permission = $Identity,$Rights,$Access
    $accessRule = New-Object -TypeName System.Security.AccessControl.FileSystemAccessRule -ArgumentList $permission
	$acl = Get-Acl -Path $Path
	$acl.AddAccessRule($accessRule)
	Set-Acl -Path $keyFullPath -AclObject $acl
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
        $Identity,

        [parameter(Mandatory = $true)]
        [System.Security.AccessControl.FileSystemRights]
        $Rights,

        [parameter(Mandatory = $true)]
        [System.Security.AccessControl.AccessControlType]
        $Access
    )

	$acl = Get-Acl -Path $Path
	$item = $acl.Access | where { $_.IdentityReference -eq $Identity -and $_.FileSystemRights.HasFlag($Rights) -and $_.AccessControlType -eq $Access }
	
	if ($item -eq $null)
	{
		return $false
	}
    
    $true
}


Export-ModuleMember -Function *-TargetResource

