function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $VirtualDiskFriendlyName
    )
 
}
 
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $VirtualDiskFriendlyName
    )
 
    Initialize-Disk -VirtualDisk (Get-VirtualDisk -FriendlyName $VirtualDiskFriendlyName) -PartitionStyle GPT -Confirm:$false
}
 
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $VirtualDiskFriendlyName
    )
 
    $result = [System.Boolean]
 
    try
    {
        $virtualDisk = Get-VirtualDisk -FriendlyName $VirtualDiskFriendlyName -ErrorAction Stop
        $disk = Get-Disk -VirtualDisk $virtualDisk
 
        if($disk.PartitionStyle -eq 'GPT')
        {
           $result = $true
        }
        else
        {
           $result = $false
        }
    }
    catch [System.Exception]
    {
        $result = $false
    }
 
    $result
}
 
Export-ModuleMember -Function *-TargetResource