$pbiConnection = Get-VstsEndpoint -Name (Get-VstsInput -Name pbiConnection)
$workspace = Get-VstsInput -Name workspace
$userUpn = Get-VstsInput -Name userUpn
$permission = Get-VstsInput -Name permission

. .\CommonUtilities.ps1

Write-Host "Importing module MicrosoftPowerBIMgmt.Profile"
Import-Module .\ps_modules\MicrosoftPowerBIMgmt.Profile

try {
    Connect-PowerBIService $pbiConnection
    
    $activityId = New-Guid
    Write-Host "Activity ID: $activityId"

    Write-Host "Getting workspace $workspace"
    $foundWorkspace = Get-Workspace -ActivityId $activityId -Workspace $workspace

    $url = "groups/{0}/users" -f $foundWorkspace.Id
    $body = @{ 
        identifier           = $userUpn
        groupUserAccessRight = $permission
        principalType        = "User"
    } | ConvertTo-Json

    Write-Host "Sending request to add user to workspace - $url"
    Write-Host "Request Body- $body"

    Invoke-PowerBIApi -ActivityId $activityId -Url $url -Method Post -Body $body

    Write-Host "User has been added to workspace successfully"	
}
catch {
    $err = Resolve-PowerBIError -Last
    Write-Error $err.Message
}