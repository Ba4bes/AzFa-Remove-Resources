<#
.SYNOPSIS
    This Azure Function deletes resources with a tag called AutoDelete set to True.
.DESCRIPTION
    This script is meant to run as part of an Azure Function app.
    It searches for resources with the Tag Autodelete with value True.
    It then sends a message to the storage account queue to activate another function.
    A percentage-scanner checks how many resources in the subscription would be deleted,
    as a security check.
    If the percentage is to high, the script will throw
.NOTES
    Written by Barbara Forbes
    4bes.nl
    @ba4bes
#>

# Input bindings are passed in via param block.
param($Timer)

# Set the tag. Change this value if you want to use a different tag.
$Tag = @{
    "AutoDelete" = "True"
}

Import-Module az
# $Resources = $null
# $ResourceGroups = $null
# # $Dependencies = $null
# $ResourceID = $null
# $Fail = $false
# Check if managed identity has been enabled and granted access to a subscription, resource group, or resource
$AzContext = Get-AzContext -ErrorAction SilentlyContinue
if (-not $AzContext.Subscription.Id) {
    Throw ("Managed identity is not enabled for this app or it has not been granted access to any Azure resources. Please see https://docs.microsoft.com/en-us/azure/app-service/overview-managed-identity for additional details.")
}

# Set the tag. Change this value if you want to use a different tag.
Write-Output "Finding Resources"
$Resources = Get-AzResource -tag $Tag -ErrorAction Stop
if ($null -eq $Resources) {
    Write-Output "No Resources found to remove"
    Exit
}
Write-Output "$($Resources.Count) Resources have been found to delete"
# Get all resources to check how large a percentage of the resources would be deleted
$AllResources = Get-AzResource

#throw if the percentage is to high( change the gt -value to your needs)
$percentage = ($Resources.count / $AllResources.count) * 100
if ($percentage -gt 30) {
    Write-Output "ERROR: Too many resources would be removed"
    Throw "Too many resources would be removed"
}

# Send messages to the storage queue, so Remove-FirstResources can be activated
Foreach ($Resource in $Resources ) {
    $ResourceID = $Resource.ResourceId
    Push-OutputBinding -Name JobQueue -Value $ResourceId
    Write-Output "performed push for $($Resource.ResourceName)"
}

