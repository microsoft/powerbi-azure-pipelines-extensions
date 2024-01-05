$pbiConnection = Get-VstsEndpoint -Name (Get-VstsInput -Name pbiConnection)
$pipeline = Get-VstsInput -Name pipeline
$groupId = Get-VstsInput -Name groupId

. .\InitTask.ps1

Add-GroupToPipeline -ActivityId $activityId -Endpoint $endpoint -Pipeline $pipeline -GroupId $groupId
