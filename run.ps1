Write-Output -InputObject "HA NVA timer trigger function executed at:$(Get-Date)"

#--------------------------------------------------------------------------
# Set firewall monitoring variables here
#--------------------------------------------------------------------------

$VM1RGName = $env:VM1RGName     # Set the Name of the primary NVA firewall
$VM1Name = $env:VM1Name      # Set the Name of the secondary NVA firewall
$groupname = $env:groupname     # Set the ResourceGroup that contains FW1
$rtsubscription = $env:rtsubscription     # Set the ResourceGroup that contains FW2
$vmsubscription = $env:vmsubscription 
$SubscriptionID =$env:SubscriptionID


#--------------------------------------------------------------------------
# Set the failover and failback behavior for the firewalls
#--------------------------------------------------------------------------


#--------------------------------------------------------------------------
# Code blocks for supporting functions
#--------------------------------------------------------------------------
try {
        $AzureContext = (Connect-AzAccount -Identity).context
    }
catch{
        Write-Output "There is no system-assigned user identity. Aborting."; 
        exit
    }

# set and store context
try {
    if($SubscriptionId -eq "") {
        Write-Output " "
        Write-Output "Set context by default."
        $AzureContext = Set-AzContext -SubscriptionName $AzureContext.Subscription -DefaultProfile $AzureContext
    }
    else {
        Write-Output " "
        Write-Output "Set context via subscription ID parameter."
        $AzureContext = Set-AzContext -SubscriptionId $SubscriptionID -DefaultProfile $AzureContext
    }
}
catch {
    Write-Error -Message $_.Exception
    throw $_.Exception
}

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
    Set-AzContext -SubscriptionId $rtsubscription
    $rt = Get-AzRouteTable -ResourceGroupName $groupname
    $oldroutes = Get-AzRouteTable -ResourceGroupName $groupname | Get-AzRouteConfig | Where-Object -Property NextHopIpAddress -Like 10.10.10.10
    foreach ($oldroutes in $oldroutes)
    {
    Set-AzRouteConfig -RouteTable $rt -Name $oldroutes.Name -AddressPrefix $oldroute.AddressPrefix -NextHopType VirtualAppliance -NextHopIpAddress 8.8.8.8 | Set-AzRoutetable
    } 
   
}

  Send-AlertMessage -message "NVA Alert: Failback to Primary FW1"



