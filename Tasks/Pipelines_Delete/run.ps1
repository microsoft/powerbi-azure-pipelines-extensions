$pbiConnection = Get-VstsEndpoint -Name (Get-VstsInput -Name pbiConnection)
$pipeline = Get-VstsInput -Name pipeline

. .\InitTask.ps1

Remove-Pipeline -ActivityId $activityId -Endpoint $endpoint -Pipeline $pipeline
