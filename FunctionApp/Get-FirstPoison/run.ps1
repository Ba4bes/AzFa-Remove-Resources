<#
.SYNOPSIS
    This Azure Function deletes resources with a tag called AutoDelete set to True.
.DESCRIPTION
This Azure Function is purely for monitoring.
It collects results from the other functions and writes them as output.
Log analytics can be used to create reports or alerts

.NOTES
    Written by Barbara Forbes
    4bes.nl
    @ba4bes
#>
# Input bindings are passed in via param block.
param([string] $FirstPoison, $TriggerMetadata)

# First perform a start sleep to make sure the resource has not been removed in the background
Start-Sleep 360

try {
    $Resource = Get-AzResource -ResourceId $FirstPoison -ErrorAction Stop
    Write-Error "ERROR: $FirstPoison has not been deleted"
}
Catch {
    Write-Output "$FirstPoison is in Poison Queue, but has been deleted"
}