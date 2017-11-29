<#==========================================================================
Script Name: SRM-HealthCheck.ps1
Created on: 4/20/2017
Created by: Chris Shaw
===========================================================================
.DESCRIPTION
This script will go through each SRM protected datastore (excluding placeholder datastores) and list the VMs
with their assigned tags.
This has been tested with PowerCLI 5.8 Release 1, vSphere 5.5/6.0U2, and SRM 5.8./6.1.1.1
.SYNTAX

#>

# Set our Parameters
<#[CmdletBinding()]Param(
  [Parameter(Mandatory=$True)]
  [string]$VCENTER,

  [Parameter(Mandatory = $False)]
  [String]$User,

  [Parameter(Mandatory = $False)]
  [String]$Password
  
)#>

function Get-SRMHealth(){

$ProtectedDS = Get-Datastore DR_* | where ({$_.Name -notlike "DR_SRM_PH*"})
$ProtectedVM = $ProtectedDS | Get-VM 
$date = (Get-Date).tostring("yyyyMMdd")
$outputfile = "D:\Output\All-SRM_Health_Chk_$Date.csv"
$allvminfo = @()

    foreach ($VM in $ProtectedVM){

        $Datacenter = $VM | get-datacenter
        $VMCluster = $VM | Get-Cluster
        $datastore = $VM | Get-Datastore DR_* | where ({$_.Name -notlike "PlacedholderDSName"})
        $datastore1 = $datastore[0]
        $datastore2 = $datastore[1]
        $datastore3 = $datastore[2]
        $Tags = $VM | Get-TagAssignment | Select-Object -Property Tag
        $Tags1 = $Tags[0]
        $Tags2 = $Tags[1]
        $Tags3 = $Tags[2]

        $properties = @{
        'Name'=$vm.Name;
        'Datacenter'=$Datacenter;
        'Tags1'=$Tags[0];
        'Tags2'=$Tags[1];
        'Tags3'=$Tags[2];
	    'Cluster'=$VMCluster;
        'datastore1'=$datastore[0];
        'datastore2'=$datastore[1];
        'datastore3'=$datastore[2];

        }
            
            $vminfo = New-Object -TypeName PSObject -Property $properties
            $allvminfo += $vminfo

    }

        $allvminfo | Select Name, Datacenter, Cluster, Datastore1, Datastore2, Datastore3, Tags1, Tags2, Tags3 | Export-Csv -append $outputfile -noTypeInformation

}

#SiteA
Connect-VIServer
    Get-SRMHealth
disconnect-viserver -confirm:$false

#SiteB
Connect-VIServer
    Get-SRMHealth
disconnect-viserver -confirm:$false



#Sends Email
$anonUser = "anonymous"
$anonPass = ConvertTo-SecureString "anonymous" -AsPlainText -Force
$anonCred = New-Object System.Management.Automation.PSCredential($anonUser, $anonPass)
$dir = "D:\Output"
$latest = Get-ChildItem -Path $dir | Sort-Object LastAccessTime -Descending | Select-Object -First 1
$latest.Fullname
$attachment = $latest.Fullname
$emailSmtpServer = ""
$emailMessage = New-Object System.Net.Mail.MailMessage
$emailMessage.From = ""
$emailMessage.To.Add( "" )
$emailMessage.Subject = ""
$emailMessage.Body = "Attached is the SRM Health Output file."
$emailMessage.Attachments.Add( $attachment )
$SMTPClient = New-Object Net.Mail.SmtpClient($emailSmtpServer)
$SMTPClient.Send($emailMessage)