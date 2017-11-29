<#==========================================================================
Script Name: SRM-HealthCheck.ps1
Created on: 4/20/2017
Created by: Chris Shaw
===========================================================================
.DESCRIPTION
This script will go through each DR protected datastore (excluding placeholder datastores) and list the VMs
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
        $datastore = $VM | Get-Datastore DR_* | where ({$_.Name -notlike "DR_SRM_PH*"})
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

#Raritan
Connect-VIServer itsusrasdvc001.jnj.com -User jnj\SA-SDNA-SRMP -Password 'V0tG(31-Cm' 
    Get-SRMHealth
disconnect-viserver -confirm:$false

#Raritan201
Connect-VIServer itsusrasdvc201.jnj.com -User jnj\SA-SDNA-SRMP -Password 'V0tG(31-Cm'
    Get-SRMHealth
disconnect-viserver -confirm:$false

#Singapore
Connect-VIServer itssgsgvc01.jnj.com -user Jnj\sa-its-sd-ap-srm-p -Password '$RM#01jnj'
    Get-SRMHealth
disconnect-viserver -confirm:$false

#Beerse
Connect-VIServer itsbebesdvc001.jnj.com -user Jnj\sa-sdeu-srmp -Password 'Wmu33RT4)='  
    Get-SRMHealth
disconnect-viserver -confirm:$false

#Ashburn
Connect-VIServer itsusabsdvc001.jnj.com -user jnj\SA-SDNA-SRMP -Password 'V0tG(31-Cm'   
    Get-SRMHealth
disconnect-viserver -confirm:$false

#Ashburn201
Connect-VIServer itsusabsdvc201.jnj.com -user jnj\SA-SDNA-SRMP -Password 'V0tG(31-Cm'   
    Get-SRMHealth
disconnect-viserver -confirm:$false

#Malaysia
Connect-VIServer itsmycysdvc001.jnj.com -user Jnj\sa-its-sd-ap-srm-p -Password '$RM#01jnj'
    Get-SRMHealth
disconnect-viserver -confirm:$false

#Hemel Hempstead
Connect-VIServer itsgbhhsdvc001.jnj.com -user Jnj\sa-sdeu-srmp -Password 'Wmu33RT4)='  
    Get-SRMHealth
disconnect-viserver -confirm:$false

#Treasury (HH)
Connect-VIServer itsgbhhsdvc101.jnj.com -user administrator@vsphere.local -Password 'P@$$word01'  
    Get-SRMHealth
disconnect-viserver -confirm:$false

#Treasury (Slough)
Connect-VIServer itsgbslsdvc101.jnj.com -user administrator@vsphere.local -Password 'P@$$word01'  
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
$emailSmtpServer = "smtp.na.jnj.com"
$emailMessage = New-Object System.Net.Mail.MailMessage
$emailMessage.From = "RA-ITSUS-SDDC_DR@ITS.JNJ.com"
$emailMessage.To.Add( "cshaw20@ITS.JNJ.com" )
$emailMessage.To.Add( "wortiz9@ITS.JNJ.com" )
$emailMessage.To.Add( "rmandav3470@ITS.JNJ.com" )
$emailMessage.To.Add( "mlieblon@ITS.JNJ.com" )
$emailMessage.To.Add( "akesar1@ITS.JNJ.com" )
$emailMessage.To.Add( "sramak15@ITS.JNJ.com" )
$emailMessage.Subject = "Raritan-SRM-Health-Output"
$emailMessage.Body = "Attached is the SRM Health Output file."
$emailMessage.Attachments.Add( $attachment )
$SMTPClient = New-Object Net.Mail.SmtpClient($emailSmtpServer)
$SMTPClient.Send($emailMessage)