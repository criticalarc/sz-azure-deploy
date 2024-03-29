function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $FriendlyName
    )
}
 
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $FriendlyName
    )
 
    New-StoragePool -FriendlyName $FriendlyName `
                    -StorageSubsystemFriendlyName 'Windows Storage*' `
                    -PhysicalDisks (Get-PhysicalDisk -CanPool $true)
}
 
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $FriendlyName
    )
 
    $result = [System.Boolean]
 
    try
    {
        $pool = Get-StoragePool -FriendlyName $FriendlyName -ErrorAction Ignore
        
        if (!$pool)
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