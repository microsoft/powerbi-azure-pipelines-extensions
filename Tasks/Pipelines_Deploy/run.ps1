$pbiConnection = Get-VstsEndpoint -Name (Get-VstsInput -Name pbiConnection)
$pipeline = Get-VstsInput -Name pipeline
$stageOrder = Get-VstsInput -Name stageOrder
$waitForCompletion = Get-VstsInput -Name waitForCompletion -AsBool
$deployType = Get-VstsInput -Name deployType
$dataflows = Get-VstsInput -Name dataflows
$datasets = Get-VstsInput -Name datasets
$reports = Get-VstsInput -Name reports
$dashboards = Get-VstsInput -Name dahsboards
$createNewWS = Get-VstsInput -Name createNewWS -AsBool
$newWsName = Get-VstsInput -Name newWsName 
$capacity = Get-VstsInput -Name capacity
$allowCreateArtifact = Get-VstsInput -Name allowCreateArtifact -AsBool
$allowOverwriteArtifact = Get-VstsInput -Name allowOverwriteArtifact -AsBool
$allowOverwriteTargetArtifactLabel = Get-VstsInput -Name allowOverwriteTargetArtifactLabel -AsBool
$allowPurgeData = Get-VstsInput -Name allowPurgeData -AsBool
$allowSkipTilesWithMissingPrerequisites = Get-VstsInput -Name allowSkipTilesWithMissingPrerequisites -AsBool
$allowTakeOver = Get-VstsInput -Name allowTakeOver -AsBool
$updateApp = Get-VstsInput -Name updateApp -AsBool

. .\CommonUtilities.ps1
. .\Utility.ps1

Write-Host "Importing module MicrosoftPowerBIMgmt.Profile"
Import-Module .\ps_modules\MicrosoftPowerBIMgmt.Profile

try {
    Connect-PowerBIService -PbiConnection $pbiConnection

    Write-Host "Getting pipeline"
    $foundPipeline = Get-Pipeline -Pipeline $pipeline

    # Prepare the request body
    switch ($stageOrder) {
        "Test" {
            $body = @{ 
                sourceStageOrder     = 0
                isBackwardDeployment = $FALSE
            }
        }

        "Production" {
            $body = @{ 
                sourceStageOrder     = 1
                isBackwardDeployment = $FALSE
            }
        }

        "Development (Backward)" {
            $body = @{ 
                sourceStageOrder     = 1
                isBackwardDeployment = $TRUE
            }
        }

        "Test (Backward)" {
            $body = @{ 
                sourceStageOrder     = 2
                isBackwardDeployment = $TRUE
            }
        }
    }

    $body.options = @{
        # Allows creating new artifact if needed on the Test stage workspace
        allowCreateArtifact                    = $allowCreateArtifact
        # Allows overwriting existing artifact if needed on the Test stage workspace
        allowOverwriteArtifact                 = $allowOverwriteArtifact        
        allowOverwriteTargetArtifactLabel      = $allowOverwriteTargetArtifactLabel      
        allowPurgeData                         = $allowPurgeData        
        allowSkipTilesWithMissingPrerequisites = $allowSkipTilesWithMissingPrerequisites
        allowTakeOver                          = $allowTakeOver
    }

    if ($createNewWS) {
        $body.newWorkspace = @{
            name       = $newWsName
            capacityId = $capacity
        }
    }

    if ($updateApp) {
        $body.updateAppSettings = @{
            updateAppInTargetWorkspace = $TRUE
        }
    }

    if ($deployType -eq "Selective") {
        $url = "pipelines/{0}/stages/{1}/artifacts" -f $foundPipeline.Id, $body.sourceStageOrder
        $artifacts = Invoke-PowerBIRestMethod -Url $url -Method Get | ConvertFrom-Json

        $body.dataflows = Proccess-Artifacts -RequestedArtifacts $dataflows -Artifacts $artifacts.dataflows -Type "dataflow"
        $body.datasets = Proccess-Artifacts -RequestedArtifacts $datasets -Artifacts $artifacts.datasets -Type "dataset"
        $body.reports = Proccess-Artifacts -RequestedArtifacts $reports -Artifacts $artifacts.reports -Type "reports"
        $body.dashboards = Proccess-Artifacts -RequestedArtifacts $dashboards -Artifacts $artifacts.dashboards -Type "dashboard"
    }

    $url = "pipelines/{0}/DeployAll" -f $foundPipeline.Id
    $body = $body | ConvertTo-Json

    Write-Host "Sending request to start deployment - $url"
    Write-Host "Request Body- $body"
    $deployResult = Invoke-PowerBIRestMethod -Url $url -Method Post -Body $body | ConvertFrom-Json

    Write-Host "Deployment requested sucessfully, Operation ID: $($deployResult.id)"

    if (!$waitForCompletion) {
        Write-Host "Skipping wait for deployment job completion"
        return
    }

    # Get the deployment operation details
    $url = "pipelines/{0}/Operations/{1}" -f $foundPipeline.Id, $deployResult.id
    $operation = Invoke-PowerBIRestMethod -Url $url -Method Get | ConvertFrom-Json    

    while ($operation.Status -eq "NotStarted" -or $operation.Status -eq "Executing") {
        Write-Host "Waiting for deployment completion, Status = $($operation.Status)"
        # Sleep for 5 seconds
        Start-Sleep -s 5

        $operation = Invoke-PowerBIRestMethod -Url $url -Method Get | ConvertFrom-Json
    }

    $message = "Deployment completed with status: {0}, Operation Id: {1}" -f $operation.Status, $deployResult.id
    if ($operation.Status -ne "Succeeded") {
        Write-Error $message
    }
    else {
        Write-Host $message
    }
}
catch {
    $err = Resolve-PowerBIError -Last
    Write-Error $err.Message
}