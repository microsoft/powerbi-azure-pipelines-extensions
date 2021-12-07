$pbiConnection = Get-VstsEndpoint -Name (Get-VstsInput -Name pbiConnection)
$pipeline = Get-VstsInput -Name pipeline

. .\CommonUtilities.ps1

Write-Host "Importing module MicrosoftPowerBIMgmt.Profile"
Import-Module .\ps_modules\MicrosoftPowerBIMgmt.Profile

try {
    Connect-PowerBIService -PbiConnection $pbiConnection

    Write-Host "Getting pipeline"
    $foundPipeline = Get-Pipeline -Pipeline $pipeline

    $url = "pipelines/{0}" -f $foundPipeline.Id

    Write-Host "Sending request to Delete pipeline - $url"

    Invoke-PowerBIRestMethod -Url $url -Method Delete

    Write-Host "Pipeline deleted successfully"
} catch {
    $err = Resolve-PowerBIError -Last
    Write-Error $err.Message
}