Write-Output -InputObject "HA NVA timer trigger function executed at:$(Get-Date)"

#--------------------------------------------------------------------------
# Set firewall monitoring variables here
#--------------------------------------------------------------------------

$VM1RGName = $env:VM1RGName     # Set the Name of the primary NVA firewall
$VM1Name = $env:VM1Name      # Set the Name of the secondary NVA firewall
$groupname = $env:groupname     # Set the ResourceGroup that contains FW1
$rtsubscription = $env:rtsubscription     # Set the ResourceGroup that contains FW2
$vmsubscription = $env:vmsubscription 
$Monitor =   $env:FWMONITOR    # "VMStatus" or "TCPPort" are valid values


#--------------------------------------------------------------------------
# Set the failover and failback behavior for the firewalls
#--------------------------------------------------------------------------


#--------------------------------------------------------------------------
# Code blocks for supporting functions
#--------------------------------------------------------------------------

Function Test-VMStatus ($VM1RGName, $VM1Name) 
 
{
  Set-AzContext -Subscription $vmsubscription 
  $VMDetail = Get-AzVM -ResourceGroupName $VM1RGName -Name $VM1Name -Status
  foreach ($VMStatus in $VMDetail.Statuses)
  { 
    $Status = $VMStatus.code
      
    if($Status.CompareTo('PowerState/running') -eq 0)
    {
      Return $False
    }
  }
  Return $True  
}
  


Function Start-Failover 
{
    Set-AzureRmContext -SubscriptionId $rtsubscription
    $rt = Get-AzRouteTable -ResourceGroupName $groupname
    $oldroutes = Get-AzRouteTable -ResourceGroupName $groupname | Get-AzRouteConfig | Where-Object -Property NextHopIpAddress -Like 10.10.10.10
    foreach ($oldroutes in $oldroutes)
    {
    Set-AzRouteConfig -RouteTable $rt -Name $oldroutes.Name -AddressPrefix $oldroute.AddressPrefix -NextHopType VirtualAppliance -NextHopIpAddress 8.8.8.8 | Set-AzRoutetable
    } 
   
}

  Send-AlertMessage -message "NVA Alert: Failback to Primary FW1"


$Password = ConvertTo-SecureString $env:SP_PASSWORD -AsPlainText -Force
$Credential = New-Object System.Management.Automation.PSCredential ($env:SP_USERNAME, $Password)
$AzureEnv = Get-AzureRmEnvironment -Name $env:AZURECLOUD
Add-AzureRmAccount -ServicePrincipal -Tenant $env:TENANTID -Credential $Credential -SubscriptionId $env:SUBSCRIPTIONID -Environment $AzureEnv
