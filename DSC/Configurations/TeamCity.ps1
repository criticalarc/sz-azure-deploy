Configuration TeamCity
{
    Import-DscResource -Module xWindowsStorage
    Import-DscResource -Module cChoco
    Import-DscResource -Module cWSUS

    Node "server"
    {
        StorageSpace CreateStorageSpace
        {
            FriendlyName = 'Repository'
        }
 
        VirtualDisk CreateVirtualDisk
        {
            FriendlyName = 'Repository'
            StoragePoolFriendlyName = 'Repository'
            Interleave = 65536
            DependsOn = "[StorageSpace]CreateStorageSpace"
        }
 
        Disk InitializeDisk
        {
            VirtualDiskFriendlyName = 'Repository'
            DependsOn = "[VirtualDisk]CreateVirtualDisk"
        }
 
        DiskPartition CreateDiskPartition
        {
            VirtualDiskFriendlyName = 'Repository'
            DriveLetter = 'R'
            DependsOn = "[Disk]InitializeDisk"
        }
        
        cChocoInstaller InstallChoco 
        { 
            InstallDir = 'C:\choco'
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
    
        cChocoPackageInstaller InstallFiddler4
        {
            Name = 'fiddler4'
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