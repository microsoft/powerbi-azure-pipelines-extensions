$pbiConnection = Get-VstsEndpoint -Name (Get-VstsInput -Name pbiConnection)
$pipeline = Get-VstsInput -Name pipeline
$stageOrder = Get-VstsInput -Name stageOrder

. .\InitTask.ps1

switch ($stageOrder) {
    "Development" {
        $numericStageOrder = 0
    }
    "Test" {
        $numericStageOrder = 1
    }
    "Production" {
        $numericStageOrder = 2
    }
}

Remove-WorkspaceFromPipeline -ActivityId $activityId -Endpoint $endpoint -Pipeline $pipeline -StageOrder $numericStageOrder