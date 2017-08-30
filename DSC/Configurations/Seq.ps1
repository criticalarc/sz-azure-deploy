Configuration Seq
{
    Import-DscResource -Module xWindowsStorage
    Import-DscResource -Module xWindowsAccessControl
    Import-DscResource -Module xNetworking
    Import-DscResource -Module cChoco
    Import-DscResource -Module cWSUS

    Node "default"
    {
        StorageSpace CreateStorageSpace
        {
            FriendlyName = 'Seq'
        }
 
        VirtualDisk CreateVirtualDisk
        {
            FriendlyName = 'Seq'
            StoragePoolFriendlyName = 'Seq'
            Interleave = 65536
            DependsOn = "[StorageSpace]CreateStorageSpace"
        }
 
        Disk InitializeDisk
        {
            VirtualDiskFriendlyName = 'Seq'
            DependsOn = "[VirtualDisk]CreateVirtualDisk"
        }
 
        DiskPartition CreateDiskPartition
        {
            VirtualDiskFriendlyName = 'Seq'
            DriveLetter = 'R'
            DependsOn = "[Disk]InitializeDisk"
        }

        xFirewall CreateFirewallRuleAllowInBoundSeq
        {
            Name                  = "Seq"
            DisplayName           = "Allow Seq"
            Enabled               = "True"
            Profile               = ("Public", "Domain", "Private")
            Direction             = "InBound"
            LocalPort             = ("5341")
            Protocol              = "TCP"
        }
        
        CertificatePermission GrantAccessToCertificates 
        { 
            Path = 'Cert:\LocalMachine\My'
            Subject = '*criticalarc*'
            Identity = 'NT AUTHORITY\NETWORK SERVICE'
            Rights = 'Read'
            Access = 'Allow'
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
            NodeIdPattern = '(?i)seq(\d+)'
            Ensure = 'Present'
        }

        cWSUSAutoRebootWithLoggedOnUsers WindowsUpdateAutoRebootWithLoggedOnUsers
        {
            Enable = 'False'
        }
    }
}