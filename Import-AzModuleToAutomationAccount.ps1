#Script to import Az module along with its dependecies into Azure Automation Account

$AutomationAccountName = "ProdInfraMon"
$AutomationAccountRG = "ProdInfraMon"

$Module = Find-Module Az

Write-Output "INFO: Total Dependencies found for Az Module :: $($Module.Dependencies.Name.Count)"

foreach ($Dependency in $Module.Dependencies.Name) {
    Write-Output "INFO: Importing Module [$($Dependency)]"
    $AzMod = Find-Module $Dependency
    New-AzAutomationModule -AutomationAccountName $AutomationAccountName -Name $AzMod.Name -ContentLinkUri "$($AZMod.RepositorySourceLocation)package/$($AzMod.Name)/$($AzMod.Version)" -ResourceGroupName $AutomationAccountRG -Verbose -ErrorAction Continue
    
    while ((Get-AzAutomationModule -AutomationAccountName $AutomationAccountName -Name $AzMod.Name -ResourceGroupName $AutomationAccountRG).ProvisioningState -eq 'Creating') {
        Start-Sleep 30
    }
}
