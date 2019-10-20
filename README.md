# AzFa-Remove-Resources

This Function apps Removes all resources with a tag that is defined in start-Function.
By default this tag is "AutoDelete":"True".
The app is meant to run on a schedule at the end of the day to clean up unwanted resources.

## Functionality

This App contains five functions.

### Start-Function

This function is triggered by a schedule. It gets all resources with the defined tag.
When it has the resources, it first does a check to see if not to many resources would be removed.
This is based on a percentage. This can be changed to your needs.
It then pushes the resourceIds to the job queue so they can be handled by the following function

### Remove-FirstResources

This Function is triggered by the job queue. If check for certain resources that are known to have dependent resources preventing it from being deleted. These resources are send to the second queue.
The other resources are removed. The amount of Jobs that can run at the same time is set at 10. If the function shows unexpected behavior, you can decrease this number for troubleshooting, as it can cause some instability.

### Remove-SecondResources

This function does the same as Remove-FirstResources, except it has a small wait at the beginning.

### Get-FirstPoison

This function gets triggered by the first poison queue. If this is hit, it checks if the resource has not been removed and creates appropriate output so alerting and monitoring is easier implemented through Log Analytics.

### Get-SecondPoison

This function gets triggered by the second poison queue. If this is hit, it checks if the resource has not been removed and creates appropriate output so alerting and monitoring is easier implemented through Log Analytics.

## Deployment

The arm template only deploys the App itself, not the code.
The repository is ready to deploy through an Azure DevOps pipeline.
For an example of how to use it, see the following blog post.
(This post is about another app, but is easily translated to this use case). The most important thing is to change the settings in `azure-pipelines.yml`:

- Change the three parameters at the top:
  - `FunctionAppName`: the name of the new app, should be globally unique
  - `AzureConnectionName`: the name of the service connection to Azure in Azure DevOps
  - `resourceGroupName`: The name of the resourcegroup the app should be placed in.

  The location is set for West Europe, you can changed that as well. See the post below for more information:

[4bes.nl - Automatic setup: Deploy Azure Functions for PowerShell with Azure DevOps](https://4bes.nl/2019/06/16/deploy-azure-functions-for-powershell-with-azure-devops/)

If you want to run this app in Azure without Azure DevOps, you can use the files in the FunctionApp folder. Don't forget the Function App needs Contributor permissions on every resource group it is supposed to remove (or at subscription level)

## Available Components

- **Deployment**
  This folder contains an ARM template to deploy the app, and a PowerShell script that sets the apps permissions
- **FunctionApp**
  This is the code for the Function app itself
- **Azure-pipelines.yml**
  a pipeline to test and deploy this app through Azure DevOps