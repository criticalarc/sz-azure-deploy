Configuration ESET
{
    Import-DscResource -Module cChoco
    Import-DscResource -Module cWSUS

    Node "default"
    {
        cChocoInstaller InstallChoco 
        { 
            InstallDir = 'C:\choco'
            ChocoInstallScriptUrl = 'https://raw.githubusercontent.com/criticalarc/sz-azure-deploy/master/Assets/Modules/cChoco/install.ps1'
        }

        cChocoPackageInstaller InstallChrome
        {
            Name = 'GoogleChrome'
            DependsOn = "[cChocoInstaller]InstallChoco"
        }
    
        cChocoPackageInstaller InstallNotePadPlusPlus
        {
            Name = 'notepadplusplus'
            DependsOn = "[cChocoInstaller]InstallChoco"
        }
    
        cChocoPackageInstaller InstallFiddler
        {
            Name = 'fiddler'
            DependsOn = "[cChocoInstaller]InstallChoco"
        }
    
        cChocoPackageInstaller InstallSysInternals
        {
            Name = 'sysinternals'
            DependsOn = "[cChocoInstaller]InstallChoco"
        }
        
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