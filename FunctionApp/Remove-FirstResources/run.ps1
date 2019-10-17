<#
.SYNOPSIS
    This Azure Function deletes resources with a tag called AutoDelete set to True.
.DESCRIPTION
    This script is meant to run as part of an Azure Function app.
    It responds to input from the job queue.
    The input will be a resourceID, the script will remove this resource.
    If a resource normally has other resources depending on it, it will be send to a second queue.
    After the recourse is removed, the script checks if the resource group it was in is empty.
    If so, the resource group is deleted as well.
.NOTES
    Written by Barbara Forbes
    4bes.nl
    @ba4bes
#>

# Input bindings are passed in via param block.
param([string] $Resourceid, $TriggerMetadata)

# Write out the queue message and insertion time to the information log.
Write-Host "PowerShell queue trigger function processed work item: $ResourceId"
Write-Host "Queue item insertion time: $($TriggerMetadata.InsertionTime)"

# Collect the resourcegroup to find out if it would need to be deleted after the resource is deleted
$ResourceName = $ResourceId.Split('/')[-1]
$ResourceGroup = (Get-AzResource -ResourceId $Resourceid).ResourceGroupName

# First see if the resource exist. This is to make sure no wrong resources are deleted
try {
    ($Resource = Get-AzResource -ResourceId $Resourceid)
}
Catch {
    Throw "Resource $ResourceName does not exist, ending script"
}
# The following resources often can't be deleted because a dependend resource needs to be deleted first.
# If the resource is in this list, it is pushed to a second queue
if ($Resource.Resourcetype -eq "Microsoft.Compute/disks" -or
    $Resource.Resourcetype -eq "Microsoft.Network/networkSecurityGroups" -or
    $Resource.Resourcetype -eq "Microsoft.Network/virtualNetworks"
    ) {
    Write-output "pushing $ResourceId to dependencies"
    Push-OutputBinding -Name JobQueue2 -Value $Resourceid
}
else {
    # The resource is removed.
    Try {
        Write-Output "Removing $ResourceName"
        Remove-AzResource -ResourceId $ResourceId -Force -ErrorAction Stop
        Write-Output "Resource Removed: $ResourceName"
    }
    # If it fails, the script throws so another attempt will be done.
    Catch {
        Write-Output "Couldn't remove $ResourceName"
        Throw $_
    }
}

# See if the ResourceGroup if empty
# If so, it is deleted
try {
    $ExistingResources = Get-AzResource -ResourceGroupName $ResourceGroup
}
Catch {
    Write-Output "$ResourceGroup could not be found, moving on"
    Continue
}
if ($null -eq $ExistingResources) {
    Write-Output "$Resourcegroup is empty, removing"
    Try {
        Remove-AzResourceGroup -Name $Resourcegroup -Force -ErrorAction Stop
    }
    Catch {
        Write-Error "Couldn't remove $($ResourceGroup.Name), $($_.Exception.Message)"

    }
}
else {
    Write-Output "$ResourceGroup is not empty, no action performed"
}
