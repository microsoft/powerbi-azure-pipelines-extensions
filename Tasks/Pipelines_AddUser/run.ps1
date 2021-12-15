$pbiConnection = Get-VstsEndpoint -Name (Get-VstsInput -Name pbiConnection)
$pipeline = Get-VstsInput -Name pipeline
$userUpn = Get-VstsInput -Name userUpn

. .\CommonUtilities.ps1

Write-Host "Importing module MicrosoftPowerBIMgmt.Profile"
Import-Module .\ps_modules\MicrosoftPowerBIMgmt.Profile

try {
    Connect-PowerBIService -PbiConnection $pbiConnection

    $activityId = New-Guid
    Write-Host "Activity ID: $activityId"

    Write-Host "Getting pipeline"
    $foundPipeline = Get-Pipeline -ActivityId $activityId -Pipeline $pipeline

    $url = "pipelines/{0}/users" -f $foundPipeline.Id
    $body = @{ 
        identifier    = $userUpn
        accessRight   = "Admin"
        principalType = "User"
    } | ConvertTo-Json

    Write-Host "Sending request to add user to pipeline - $url"
    Write-Host "Request Body- $body"

    Invoke-PowerBIApi -ActivityId $activityId -Url $url -Method Post -Body $body

    Write-Host "User has been added to pipeline successfully"   
}
catch {
    $err = Resolve-PowerBIError -Last
    Write-Error $err.Message
}