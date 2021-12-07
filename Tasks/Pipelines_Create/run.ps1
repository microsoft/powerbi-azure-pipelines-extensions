$pbiConnection = Get-VstsEndpoint -Name (Get-VstsInput -Name pbiConnection)
$displayName = Get-VstsInput -Name displayName
$description = Get-VstsInput -Name description

. .\CommonUtilities.ps1

Write-Host "Importing module MicrosoftPowerBIMgmt.Profile"
Import-Module .\ps_modules\MicrosoftPowerBIMgmt.Profile

try {
    Connect-PowerBIService -PbiConnection $pbiConnection

    $body = @{ 
        displayName = $displayName
        description = $description
    } | ConvertTo-Json

    Write-Host "Sending request to create a new deployment pipeline"
    Write-Host "Request Body- $body"

    $newPipeline = Invoke-PowerBIRestMethod -Url "pipelines"  -Method Post -Body $body | ConvertFrom-Json

    Write-Host "New deployment pipeline created successfully - Id = $($newPipeline.Id)"
} catch {
    $err = Resolve-PowerBIError -Last
    Write-Error $err.Message
}
