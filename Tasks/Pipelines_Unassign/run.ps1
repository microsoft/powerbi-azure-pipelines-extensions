$pbiConnection = Get-VstsEndpoint -Name (Get-VstsInput -Name pbiConnection)
$pipeline = Get-VstsInput -Name pipeline
$stageOrder = Get-VstsInput -Name stageOrder -AsInt

. .\CommonUtilities.ps1

Write-Host "Importing module MicrosoftPowerBIMgmt.Profile"
Import-Module .\ps_modules\MicrosoftPowerBIMgmt.Profile

try {
    Connect-PowerBIService -PbiConnection $pbiConnection
    
    $activityId = New-Guid
    Write-Host "Activity ID: $activityId"

    Write-Host "Getting pipeline"
    $foundPipeline = Get-Pipeline -ActivityId $activityId -Pipeline $pipeline

    $url = "pipelines/{0}/stages/{1}/unassignWorkspace" -f $foundPipeline.Id, $stageOrder

    Write-Host "Sending request to assign workspace to pipeline - $url"

    Invoke-PowerBIApi -ActivityId $activityId -Url $url -Method Post -Body $body

    Write-Host "Workspace has been removed from pipeline successfully"  
}
catch {
    $err = Resolve-PowerBIError -Last
    Write-Error $err.Message
}