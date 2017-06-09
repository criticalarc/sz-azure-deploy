Configuration Apps
{
    Import-DscResource -Module xWindowsAccessControl
    Import-DscResource -Module cChoco

    Node "default"
    {
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
    }
}