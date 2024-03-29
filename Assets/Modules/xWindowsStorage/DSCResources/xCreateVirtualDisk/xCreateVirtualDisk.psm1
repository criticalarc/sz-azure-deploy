function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $FriendlyName,
 
        [parameter(Mandatory = $true)]
        [System.String]
        $StoragePoolFriendlyName,
 
        [parameter(Mandatory = $true)]
        [System.UInt32]
        $Interleave,
 
        [parameter(Mandatory = $false)]
        [System.UInt32]
        $NumberOfColumns = 0
    )
 
}
 
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $FriendlyName,
 
        [parameter(Mandatory = $true)]
        [System.String]
        $StoragePoolFriendlyName,
 
        [parameter(Mandatory = $true)]
        [System.UInt32]
        $Interleave,
 
        [parameter(Mandatory = $false)]
        [System.UInt32]
        $NumberOfColumns = 0
    )
 
    Write-Debug $FriendlyName
 
	if ($NumberOfColumns -eq 0)
	{
		$disks = Get-PhysicalDisk -StoragePool (Get-StoragePool -FriendlyName $StoragePoolFriendlyName)
		$NumberOfColumns = $disks.Count
	}
 
    New-VirtualDisk -FriendlyName $FriendlyName `
                    -StoragePoolFriendlyName $StoragePoolFriendlyName `
                    -NumberOfColumns $NumberOfColumns `
					-Interleave $Interleave `
                    -ResiliencySettingName Simple `
					–UseMaximumSize
 
}
 
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $FriendlyName,
 
        [parameter(Mandatory = $true)]
        [System.String]
        $StoragePoolFriendlyName,
 
        [parameter(Mandatory = $true)]
        [System.UInt32]
        $Interleave,
 
        [parameter(Mandatory = $false)]
        [System.UInt32]
        $NumberOfColumns = 0
    )
 
    Write-Debug $FriendlyName
 
    $result = [System.Boolean]
 
    try
    {
        $disk = Get-VirtualDisk -FriendlyName $FriendlyName -ErrorAction Ignore
        
        if (!$disk)
        {
            $result = $false
        }
        else
        {
            $result = $true
        }
    }
    catch [System.Exception]
    {
        $result = $false
    }
 
    Write-Debug $result
 
    $result
}
 
Export-ModuleMember -Function *-TargetResource