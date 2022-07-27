Configuration Apps
{
    Import-DscResource -Module xWindowsAccessControl
    Import-DscResource -Module xPSDesiredStateConfiguration
    Import-DscResource -ModuleName WindowsDefender

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
        
        xGroup AddNetworkServiceToPerfMonUsers
        {
            GroupName = 'Performance Monitor Users'
            Ensure = 'Present'
            MembersToInclude = 'S-1-5-20'
        }
        
        [string[]]$exclusionPath = "C:\Program Files\Microsoft Service Fabric\","D:\SvcFab\","C:\choco\";
        [string[]]$exlusionProcess = "Fabric.exe","FabricHost.exe","FabricInstallerService.exe","FabricSetup.exe","FabricDeployer.exe","ImageBuilder.exe","FabricGateway.exe","FabricDCA.exe","FabricFAS.exe","FabricUOS.exe","FabricRM.exe","FileStoreService.exe","CriticalArc.SafeZone.Azure.Messaging.Service.exe","CriticalArc.SafeZone.Azure.Command.Service.exe";

        WindowsDefender x
        { 
            IsSingleInstance = 'Yes';
            ExclusionPath = $exclusionPath;
            ExclusionProcess = $exlusionProcess;
        }
    }
}