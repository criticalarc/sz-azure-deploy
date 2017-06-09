function Get-TargetResource {
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
	param (
		[parameter(Mandatory = $true)]
		[System.String]
		$TargetGroup
	)
    Write-Verbose "Get the Windows Server Update Service Target group"
	Try {
        $Group = Get-ItemPropertyValue -path "HKLM:\SOFTWARE\Policies\Microsoft\windows\WindowsUpdate" -name TargetGroup -ErrorAction SilentlyContinue
    }
    Catch {
        $Group = "NO_GROUP"
    }

	$returnValue = @{
		TargetGroup = $Group
	}

	$returnValue
}


function Set-TargetResource {
	[CmdletBinding()]
	param (
		[parameter(Mandatory = $true)]
		[System.String]
		$TargetGroup,

		[ValidateSet("Absent","Present")]
		[System.String]
		$Ensure
	)

    if ($Ensure -eq "Present") {
        Write-Verbose "Set the Windows Server Update Service Target group to: $TargetGroup"
        Set-ItemProperty -path "HKLM:\SOFTWARE\Policies\Microsoft\windows\WindowsUpdate" -name TargetGroupEnabled -value 1 -type dword -force
    }
    else {
        Write-Verbose "Remove the Windows Server Update Service Target group"
        Set-ItemProperty -path "HKLM:\SOFTWARE\Policies\Microsoft\windows\WindowsUpdate" -name TargetGroupEnabled -value 0 -type dword -force
    }
    
    Set-ItemProperty -path "HKLM:\SOFTWARE\Policies\Microsoft\windows\WindowsUpdate" -name TargetGroup -value $TargetGroup -type String -force
   
}


function Test-TargetResource {
	[CmdletBinding()]
	[OutputType([System.Boolean])]
	param (
		[parameter(Mandatory = $true)]
		[System.String]
		$TargetGroup,

		[ValidateSet("Absent","Present")]
		[System.String]
		$Ensure
	)
    
    Write-Verbose "Test if the Windows Server Update Service Target group is set to: $TargetGroup"
    Try {
        $Status = Get-ItemPropertyValue -path "HKLM:\SOFTWARE\Policies\Microsoft\windows\WindowsUpdate" -name TargetGroupEnabled -ErrorAction SilentlyContinue
        $Group = Get-ItemPropertyValue -path "HKLM:\SOFTWARE\Policies\Microsoft\windows\WindowsUpdate" -name TargetGroup -ErrorAction SilentlyContinue
    }
    Catch {
        $Status = "0"
        $Group = ""
    }

	switch ($Ensure) {
        "Present" {
            if ($status -eq "1") {
                if ($TargetGroup -eq $Group) {
                    $Return = $true
                }
                else {
                    $Return = $false
                }
            }
            else {                            
                $Return = $false
            }        
        }
        "Absent" {
            if ($status -eq "0") {
                $Return = $true
            }
            else {
                $Return = $false
            }        
        }
    }
    $Return

}

Export-ModuleMember -Function *-TargetResource

