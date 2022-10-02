$pbiConnection = Get-VstsEndpoint -Name (Get-VstsInput -Name pbiConnection)
$pipeline = Get-VstsInput -Name pipeline
$stageOrder = Get-VstsInput -Name stageOrder -AsInt
$workspace = Get-VstsInput -Name workspace

. .\InitTask.ps1

Add-WorkspaceToPipeline -ActivityId $activityId -Endpoint $endpoint -Pipeline $pipeline -StageOrder $stageOrder -Workspace $workspace
