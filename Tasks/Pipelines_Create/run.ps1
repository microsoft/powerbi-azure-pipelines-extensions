$pbiConnection = Get-VstsEndpoint -Name (Get-VstsInput -Name pbiConnection)
$displayName = Get-VstsInput -Name displayName
$description = Get-VstsInput -Name description

. .\InitTask.ps1

New-Pipeline -ActivityId $activityId -Endpoint $endpoint -DisplayName $displayName -Description $description