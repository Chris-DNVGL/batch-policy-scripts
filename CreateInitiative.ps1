$initiativeDefRootFolder = "$(System.DefaultWorkingDirectory)/Policyasfolder Repo/initiatives"
$subscriptionName = "$(subscriptionName)"

class InitiativeDef {
    [string]$InitiativeName
    [string]$InitiativeRulePath
}

function Select-Initiatives {
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true)]
        [System.IO.DirectoryInfo[]]$InitiativeFolders
    )

    Write-Verbose "Processing initiatives"
    $initiativeList = @()
    foreach ($initiativeDefinition in $InitiativeFolders) {
        $initiative = New-Object -TypeName InitiativeDef
        $initiative.InitiativeName = $initiativeDefinition.Name
        $initiative.InitiativeRulePath = $($initiativeDefinition.FullName + "\policyset.json")
        $initiativeList += $initiative
    }

    return $initiativeList
}

function Add-Initiatives {
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true)]
        [InitiativeDef[]]$Initiatives,
        [String]$subscriptionId
    )

    Write-Verbose "Creating Initiatives definitions"
    $initiativeDefList = @()
    foreach ($initiative in $Initiatives) {
        $initiativeDef = New-AzureRmPoliicySetDefinition -Name $initiative.InitiativeName -PolicyDefinition $initiative.InitiativeRulePath  -SubscriptionId $subscriptionId -Metadata '{"category":"Pipeline"}'
        $initiativeDefList += $initiativeDef
    }
    return $initiativeDefList
}

$subscriptionId = (Get-AzureRmSubscription -SubscriptionName $subscriptionName).Id
Write-Verbose $initiativeDefRootFolder
Write-Verbose $subscriptionId

#get list of policy folders
$initiative = Select-Initiatives -InitiativeFolders (Get-ChildItem -Path $initiativeDefRootFolder -Directory)
$initiativeDefinitions = Add-Initiatives -Initiatives $initiative -subscriptionId $subscriptionId
$initiativeDefsJson = ($initiativeDefinitions | ConvertTo-Json -Depth 10 -Compress)

Write-Host "##vso[task.setvariable variable=PolicyDefs]$initiativeDefsJson"


