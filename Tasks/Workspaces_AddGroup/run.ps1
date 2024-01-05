$pbiConnection = Get-VstsEndpoint -Name (Get-VstsInput -Name pbiConnection)
$workspace = Get-VstsInput -Name workspace
$groupId = Get-VstsInput -Name groupId
$permission = Get-VstsInput -Name permission

. .\InitTask.ps1

Add-GroupToWorkspace -ActivityId $activityId -Endpoint $endpoint -Workspace $workspace -GroupId $groupId -Permission $permission
