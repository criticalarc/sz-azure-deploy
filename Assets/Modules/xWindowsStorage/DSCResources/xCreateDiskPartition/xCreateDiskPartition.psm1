function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $VirtualDiskFriendlyName,
    
        [parameter(Mandatory = $true)]
        [System.Char]
        $DriveLetter
    )
}
 
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $VirtualDiskFriendlyName,
    
        [parameter(Mandatory = $true)]
        [System.Char]
        $DriveLetter
	)
 
    Get-VirtualDisk -FriendlyName $VirtualDiskFriendlyName `
    | Get-Disk `
    | New-Partition -UseMaximumSize -DriveLetter $DriveLetter `
    | Format-Volume
}
 
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $VirtualDiskFriendlyName,
    
        [parameter(Mandatory = $true)]
        [System.Char]
        $DriveLetter
    )
 
    $result = [System.Boolean]
 
    try
    {
        $virtualDisk = Get-VirtualDisk -FriendlyName $VirtualDiskFriendlyName -ErrorAction Stop
        $disk = Get-Disk -VirtualDisk $virtualDisk
 
        $partition = Get-Partition -DiskNumber $disk.Number
 
        if (!$partition.DriveLetter)
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
 
    $result
}
 
Export-ModuleMember -Function *-TargetResource