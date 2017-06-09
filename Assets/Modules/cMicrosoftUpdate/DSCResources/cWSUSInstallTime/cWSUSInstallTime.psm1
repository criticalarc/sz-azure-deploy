function Get-TargetResource {
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
	param (
		[parameter(Mandatory = $true)]
		[System.Int32]
		$Time,

		[parameter(Mandatory = $false)]
		[System.String]
		$NodeIdPattern
	)

    Write-Verbose "Get the Windows Server Update Service Installation time"

    Try {
        $InstallTime = Get-ItemPropertyValue -path "HKLM:\SOFTWARE\Policies\Microsoft\windows\WindowsUpdate\AU" -name ScheduledInstallTime -ErrorAction SilentlyContinue
    }
    Catch {
        $InstallTime = 0
    }

	if ($NodeIdPattern) {
		$nodeId = [regex]::Match($env:ComputerName, $NodeIdPattern).Groups[1].Captures.Value
		
		if ($nodeId) {
			$InstallTime = [datetime]::Today.AddHours($InstallTime).AddHours(-$nodeId).TimeOfDay.Hours
		}
	}
	
    $returnValue = @{
        Time = $InstallTime,
		NodeIdPattern = $NodeIdPattern
    }

    $returnValue
}


function Set-TargetResource {
	[CmdletBinding()]
	param (
		[parameter(Mandatory = $true)]
		[System.Int32]
		$Time,

		[parameter(Mandatory = $false)]
		[System.String]
		$NodeIdPattern,

		[ValidateSet("Absent","Present")]
		[System.String]
		$Ensure
	)
    
	if ($NodeIdPattern) {
		$nodeId = [regex]::Match($env:ComputerName, $NodeIdPattern).Groups[1].Captures.Value
		
		if ($nodeId) {
			$Time = [datetime]::Today.AddHours($Time).AddHours($nodeId).TimeOfDay.Hours
		}
	}
	
    if ($Ensure -eq "Present") {
        Write-Verbose "Set the Windows Server Update Service Installation time to: $time"
        Set-ItemProperty -path "HKLM:\SOFTWARE\Policies\Microsoft\windows\WindowsUpdate\AU" -name ScheduledInstallTime -Value $Time -type dword -Force
    }
    else {
        Write-Verbose "Remove the Windows Server Update Service Installation time"
        Set-ItemProperty -path "HKLM:\SOFTWARE\Policies\Microsoft\windows\WindowsUpdate\AU" -name ScheduledInstallTime -Value "" -type dword -Force
    }

}


function Test-TargetResource {
	[CmdletBinding()]
	[OutputType([System.Boolean])]
	param (
		[parameter(Mandatory = $true)]
		[System.Int32]
		$Time,

		[parameter(Mandatory = $false)]
		[System.String]
		$NodeIdPattern,

		[ValidateSet("Absent","Present")]
		[System.String]
		$Ensure
	)

    Try {
        $InstallTime = Get-ItemPropertyValue -path "HKLM:\SOFTWARE\Policies\Microsoft\windows\WindowsUpdate\AU" -name ScheduledInstallTime -ErrorAction SilentlyContinue
    }
    Catch {
        $InstallTime = 0
    }

	if ($NodeIdPattern) {
		$nodeId = [regex]::Match($env:ComputerName, $NodeIdPattern).Groups[1].Captures.Value
		
		if ($nodeId) {
			$Time = [datetime]::Today.AddHours($Time).AddHours($nodeId).TimeOfDay.Hours
		}
	}
	
    Switch ($Ensure) {
        'Present' {
            if ($Time -eq $InstallTime) {
                $Return = $true
            }
            else {
                $Return = $false
            }
        }
        'Absent' {
            if ($Time -eq $InstallTime) {
                $Return = $false
            }
            else {
                $Return = $true
            }
        }
    }

    $Return
}


Export-ModuleMember -Function *-TargetResource

