Configuration Raven
{
    Import-DscResource -Module xWindowsStorage
    Import-DscResource -Module xWindowsAccessControl
    Import-DscResource -Module xNetworking
    Import-DscResource -Module cChoco
    Import-DscResource -Module cMicrosoftUpdate

    Node "default"
    {
        StorageSpace CreateStorageSpace
        {
            FriendlyName = 'RavenDB'
        }
 
        VirtualDisk CreateVirtualDisk
        {
            FriendlyName = 'RavenDB'
            StoragePoolFriendlyName = 'RavenDB'
            Interleave = 65536
            DependsOn = "[StorageSpace]CreateStorageSpace"
        }
 
        Disk InitializeDisk
        {
            VirtualDiskFriendlyName = 'RavenDB'
            DependsOn = "[VirtualDisk]CreateVirtualDisk"
        }
 
        DiskPartition CreateDiskPartition
        {
            VirtualDiskFriendlyName = 'RavenDB'
            DriveLetter = 'R'
            DependsOn = "[Disk]InitializeDisk"
        }

        xFirewall CreateFirewallRuleAllowInBoundRavenDB
        {
            Name                  = "RavenDB"
            DisplayName           = "Allow RavenDB"
            Enabled               = "True"
            Profile               = ("Public", "Domain", "Private")
            Direction             = "InBound"
            LocalPort             = ("8080")
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
            Mode = 'AllowUserConfig'
        }
        
        cWSUSInstallDay WindowsUpdateInstallDay
        {
            Day = 'Everyday'
        }
        
        cWSUSInstallDay WindowsUpdateInstallTime
        {
            Time = 4
            NodeIdPattern = 'rvn(\d+)'
        }
    }
}