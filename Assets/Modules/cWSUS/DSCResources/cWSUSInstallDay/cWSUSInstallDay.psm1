function Get-TargetResource {
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
	param (
		[parameter(Mandatory = $true)]
		[ValidateSet("EveryDay","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday","Sunday")]
		[System.String]
		$Day
	)

	Write-Verbose "Get the Windows Server Update Service Installation day"
    
    Try {
        $InstallDayFlag = Get-ItemPropertyValue -path "HKLM:\SOFTWARE\Policies\Microsoft\windows\WindowsUpdate\AU" -name ScheduledInstallDay -ErrorAction SilentlyContinue
		$Ensure = 'Present'
    }
    Catch {
        $InstallDayFlag = "-1"
		$Ensure = 'Absent'
    }

    Switch ($InstallDayFlag) {
            "0"      {$InstallDay = "EveryDay"}
            "1"      {$InstallDay = "Sunday"}
            "2"      {$InstallDay = "Monday"}
            "3"      {$InstallDay = "Thuesday"}
            "4"      {$InstallDay = "Wednesday"}
            "5"      {$InstallDay = "Thursday"}
            "6"      {$InstallDay = "Friday"}
            "7"      {$InstallDay = "Saturday"}
    }

    $returnValue = @{
		Day = $InstallDay
		Ensure = $Ensure
	}
    
    $ReturnValue
}


function Set-TargetResource {
	[CmdletBinding()]
	param (
		[parameter(Mandatory = $true)]
		[ValidateSet("EveryDay","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday","Sunday")]
		[System.String]
		$Day,

		[ValidateSet("Absent","Present")]
		[System.String]
		$Ensure
	)

     if ($Ensure -eq "Present") { 
        Write-Verbose "Set the Windows Server Update Service Installation day to $Day"
        
        Switch ($Day) {
            "EveryDay"      {$InstallDayFlag = 0}
            "Sunday"        {$InstallDayFlag = 1}
            "Monday"        {$InstallDayFlag = 2}
            "Thuesday"      {$InstallDayFlag = 3}
            "Wednesday"     {$InstallDayFlag = 4}
            "Thursday"      {$InstallDayFlag = 5}
            "Friday"        {$InstallDayFlag = 6}
            "Saturday"      {$InstallDayFlag = 7}
        }

		Set-ItemProperty -path "HKLM:\SOFTWARE\Policies\Microsoft\windows\WindowsUpdate\AU" -name ScheduledInstallDay -Value $InstallDayFlag -type dword -force
	 }
     else { 
        Write-Verbose "Unset the Windows Server Update Service Installation day"
		Remove-ItemProperty -path "HKLM:\SOFTWARE\Policies\Microsoft\windows\WindowsUpdate\AU" -name ScheduledInstallDay -force
     }


}


function Test-TargetResource {
	[CmdletBinding()]
	[OutputType([System.Boolean])]
	param (
		[parameter(Mandatory = $true)]
		[ValidateSet("EveryDay","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday","Sunday")]
		[System.String]
		$Day,

		[ValidateSet("Absent","Present")]
		[System.String]
		$Ensure
	)
    
    Try {
        $InstallDayFlag = Get-ItemPropertyValue -path "HKLM:\SOFTWARE\Policies\Microsoft\windows\WindowsUpdate\AU" -name ScheduledInstallDay -ErrorAction SilentlyContinue
    }
    Catch {
        $InstallDayFlag = "-1"
    }

    Switch ($InstallDayFlag) {
            "0"      {$InstallDay = "EveryDay"}
            "1"      {$InstallDay = "Sunday"}
            "2"      {$InstallDay = "Monday"}
            "3"      {$InstallDay = "Thuesday"}
            "4"      {$InstallDay = "Wednesday"}
            "5"      {$InstallDay = "Thursday"}
            "6"      {$InstallDay = "Friday"}
            "7"      {$InstallDay = "Saturday"}
    }

    Write-Verbose "Test the Windows Server Update Service Installation day"

    Switch ($Ensure) {
        'Present' {
            if ($Day -eq $InstallDay) {
                $Return = $true
            }
            else {
                $Return = $false
            }
        }
        'Absent' {
            if ($Day -eq $InstallDay) {
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

