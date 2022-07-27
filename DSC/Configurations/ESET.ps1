Configuration ESET
{
    Import-DscResource -Module cWSUS

    Node "default"
    {
        cWSUSUpdateMode WindowsUpdateMode
        {
            Mode = 'DownloadAndInstall'
        }
        
        cWSUSInstallDay WindowsUpdateInstallDay
        {
            Day = 'EveryDay'
            Ensure = 'Present'
        }
        
        cWSUSInstallTime WindowsUpdateInstallTime
        {
            Time = 4
            Ensure = 'Present'
        }

        cWSUSAutoRebootWithLoggedOnUsers WindowsUpdateAutoRebootWithLoggedOnUsers
        {
            Enable = 'False'
        }
    }
}