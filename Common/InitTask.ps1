Import-Module -Force .\ps_modules\PowerBIApiUtils

$activityId = New-Guid
Write-Host "Activity ID: $activityId"

$endpoint = Connect-PowerBIService -PbiConnection $pbiConnection