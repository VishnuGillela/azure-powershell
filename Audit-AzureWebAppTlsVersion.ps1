#---------------------------------------------------------[Metadata]---------------------------------------------------------------
<#
.SYNOPSIS
    Script to audit TLS minimum version on azure web apps accross subscription/subscriptions
.DESCRIPTION
    This script takes either subscription name(s) as commma seperated values and audit all azure web apps in those subscriptions. 
    Output will be exported to a csv file in the execution folder of the script.
    If no subscription names are provided as input, script will get list of subscriptions and execute audit on all subscriptions.

.PARAMETER 
    1. SubscriptionNames:
            One/more commna seperated subscription names. This is optional input and if not provided, script will get list of subscription 
            during run time and execute audit on all subscriptions.
.NOTES
    Version: 1.0
    Author: Vishnu Gillela
    Creation Date: 23-September-2020
    Purpose/Change: Audit TLS Minimum Version On Web App In Provided Subscription.
 
.EXAMPLE
    .\Audit-MinimumTLSVersionWebApp.ps1 -SubscriptionNames "PayAsYouGo-1,AzureContributionSubscription"
#>
 
#---------------------------------------------------------[Parameters Block]-------------------------------------------------------
[CmdletBinding()]
param (
    [Parameter(Mandatory = $false,
        HelpMessage = "Enter subscription name(s) in a comma seperated format. If not provided script will execute on all subscriptions")]
    [string] $SubscriptionNames
)

#----------------------------------------------------------[Declarations]----------------------------------------------------------

$ErrorActionPreference = "Stop"
$OutputCsvFile = $PSScriptRoot + "\Audit_WebApp_TLS_MinimumVersion.csv"

#-----------------------------------------------------------[Functions]------------------------------------------------------------

#-----------------------------------------------------------[Execution]------------------------------------------------------------

#Connect Azure
Connect-AzAccount

#If SubscriptionNames input is not provided, script will list all subscription names that user/SPA have access
if ($SubscriptionNames) {
    $Subscriptions = ($SubscriptionNames).Split(',')
}
else {
    $Subscriptions = (Get-AzSubscription).Name
}

#Declaring empty array to store output 
$WebAppsTlsVersions = @()

#Iterate through each subscription 
foreach ($Subscription in $Subscriptions) {
    
    #Set Subscription Context
    try {
        Set-AzContext -Subscription $Subscription
    }
    catch {
        Write-Output "ERROR: Setting Subscription Context Failed With Error `n $_"
    }

    #Get list of Azure web apps
    try {
        Write-Output "INFO: Listing all web apps in subscription [$($Subscription)]"
        $apps = Get-AzWebApp
    }
    catch {
        Write-Output "ERROR: Failed to list web apps in subscription [$($Subscription)] with error `n $_"
    }

    Write-Output "INFO: $($apps.Count) web apps found in subscription [$($Subscription)]"

    #Iterate through each web app to access minimum TLS version property
    foreach ($app in $apps) {
    
        #Get TLS Version from web app properties
        Write-Output "INFO: Accessing MinTlsVersion property for web app [$($app.Name)]"
        $tls = "{0:n1}" -f (Get-AzWebApp -ResourceGroupName $app.ResourceGroup -Name $app.Name).SiteConfig.MinTlsVersion

        #TempObj to store data for current iteration
        $TempObj = New-Object psobject -Property @{
            'WebApp Name'          = $app.Name
            'WebApp ResourceGroup' = $app.ResourceGroup
            'Minimum TLS Version'  = $tls
            'Subscription Name'    = $Subscription
        }

        #Add data in current iteration tempobj to output array
        $WebAppsTlsVersions += $TempObj 
    }
}

$WebAppsTlsVersions | Export-Csv -Path $OutputCsvFile -NoTypeInformation -Force
