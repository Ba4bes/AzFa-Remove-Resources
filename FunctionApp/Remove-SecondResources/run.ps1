<#
.SYNOPSIS
    This Azure Function deletes resources with a tag called AutoDelete set to True.
.DESCRIPTION
    This script is meant to run as part of an Azure Function app.
    It responds to input from the job queue.
    The input will be a resourceID, the script will remove this resource.
    As this part works on the resources that need to be removes last, it takes a pause before starting.
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

# As these resources need a delay, a small pause is build in.
Write-output "Performing wait to give resources some time"
Start-Sleep 120
Write-output "starting with tasks"

# First see if the resource exist. This is to make sure no wrong resources are deleted
try {
    ($Resource = Get-AzResource -ResourceId $Resourceid)
}
Catch {
    Throw "Resource $ResourceName does not exist, ending script"
}
# The resource is removed.
Try {
    Write-Output "Removing $ResourceName"
    Remove-AzResource -ResourceId $ResourceId -Force -ErrorAction Stop
    Write-Output "Resource Removed: $ResourceName"
}
Catch {
    Write-Output "Couldn't remove $ResourceName"
    Throw $_
}

# See if the ResourceGroup if empty
# Collect the resourcegroups and see if they are empty. If so, delete them
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
