$pbiConnection = Get-VstsEndpoint -Name (Get-VstsInput -Name pbiConnection)
$pipeline = Get-VstsInput -Name pipeline
$userUpn = Get-VstsInput -Name userUpn

. .\InitTask.ps1

Add-UserToPipeline -ActivityId $activityId -Endpoint $endpoint -Pipeline $pipeline -UserUpn $userUpn