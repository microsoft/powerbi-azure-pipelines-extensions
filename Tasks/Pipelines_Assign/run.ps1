$pbiConnection = Get-VstsEndpoint -Name (Get-VstsInput -Name pbiConnection)
$pipeline = Get-VstsInput -Name pipeline
$stageOrder = Get-VstsInput -Name stageOrder -AsInt
$workspace = Get-VstsInput -Name workspace

. .\CommonUtilities.ps1

Write-Host "Importing module MicrosoftPowerBIMgmt.Profile"
Import-Module .\ps_modules\MicrosoftPowerBIMgmt.Profile

try {
    Connect-PowerBIService -PbiConnection $pbiConnection

    $activityId = New-Guid
    Write-Host "Activity ID: $activityId"
    
    Write-Host "Getting pipeline"
    $foundPipeline = Get-Pipeline -ActivityId $activityId -Pipeline $pipeline

    Write-Host "Getting workspace"
    $foundWorkspace = Get-Workspace -ActivityId $activityId -Workspace $workspace

    $url = "pipelines/{0}/stages/{1}/assignWorkspace" -f $foundPipeline.Id, $stageOrder
    $body = @{ 
        workspaceId = $foundWorkspace.Id
    } | ConvertTo-Json

    Write-Host "Sending request to assign workspace to pipeline - $url"
    Write-Host "Request Body- $body"

    Invoke-PowerBIApi -ActivityId $activityId -Url $url -Method Post -Body $body

    Write-Host "Workspace has been assigned to pipeline successfully"
}
catch {
    $err = Resolve-PowerBIError -Last
    Write-Error $err.Message
}