$pbiConnection = Get-VstsEndpoint -Name (Get-VstsInput -Name pbiConnection)
$workspace = Get-VstsInput -Name workspace
$userUpn = Get-VstsInput -Name userUpn
$permission = Get-VstsInput -Name permission

. .\InitTask.ps1

Add-UserToWorkspace -ActivityId $activityId -Endpoint $endpoint -Workspace $workspace -UserUpn $userUpn -Permission $permission
