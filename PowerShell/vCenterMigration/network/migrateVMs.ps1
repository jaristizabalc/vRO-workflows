﻿param(  
        [string]$vcenter,
        [string]$cluster
)

#Migrate Guest Network
$vms = Get-VM -Location (Get-Cluster -Name $cluster -Server $vcenter)
foreach($vm in $vms){
    $netadapters = Get-NetworkAdapter $vm 
    foreach ($adapter in $netadapters) {
        Write-Host "Setting adapter" $adapter.NetworkName on $vm $adapter
        Set-NetworkAdapter -NetworkAdapter $adapter -PortGroup (Get-VirtualPortGroup -VMhost $vm.VMHost -Standard -Name $adapter.NetworkName) -Confirm:$false
    }
}


#run  a connectivity test on all VMs
$results = @()
$vms = Get-VM -Location (Get-Cluster -Name $cluster -Server $vcenter)
foreach($vm in $vms)
{
  if($vm.PowerState -eq "PoweredOn")
  {
    Write-Host "Pinging" $vm
    if(!(Test-Connection -Cn $vm -Count 1 -ea 0 -quiet))
    {
            Write-Host "Trying second option for" $vm.Name
            if(!(Test-Connection -Cn $vm.Guest.IPAddress[0] -Count 1 -ea 0 -quiet))
            {
                $pass = "false"
                Write-Host "BOOOO!!!"
            }
            else 
            {
                $pass = "true"
                Write-Host "NICE!!!"
            }
    }
    else
    {
        $pass = "true"
        Write-Host "NICE!!!"
    } 
    $details = @{ 
        Pass = $pass
        VM = $vm
               }
    $results += New-Object PSObject -Property $details 
    }
}

$results | Export-Csv -Path .\Connectivity_test2_cluster.csv –NoTypeInformation