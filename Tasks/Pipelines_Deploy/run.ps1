$pbiConnection = Get-VstsEndpoint -Name (Get-VstsInput -Name pbiConnection)
$pipeline = Get-VstsInput -Name pipeline
$stageOrder = Get-VstsInput -Name stageOrder
$note = Get-VstsInput -Name note
$waitForCompletion = Get-VstsInput -Name waitForCompletion -AsBool
$deployType = Get-VstsInput -Name deployType
$dataflows = Get-VstsInput -Name dataflows
$datamarts = Get-VstsInput -Name datamarts
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

. .\InitTask.ps1

Start-PipelineDeployment -ActivityId $activityId -Endpoint $endpoint -Pipeline $pipeline -StageOrder $stageOrder -Note $note -WaitForCompletion $waitForCompletion -DeployType $deployType -Dataflows $dataflows -Datamarts $datamarts -Datasets $datasets -Reports $reports -Dashboards $dashboards -CreateNewWS $createNewWS -NewWsName $newWsName -Capacity $capacity -AllowCreateArtifact $allowCreateArtifact -AllowOverwriteArtifact $allowOverwriteArtifact -AllowOverwriteTargetArtifactLabel $allowOverwriteTargetArtifactLabel -AllowPurgeData $allowPurgeData -AllowSkipTilesWithMissingPrerequisites $allowSkipTilesWithMissingPrerequisites -AllowTakeOver $allowTakeOver -UpdateApp $updateApp
