<#
Create a file with name '~\Tasks\Tests\Config\config.ps1'
With the following template:

    $pbiConnection = @{
        Auth = @{
            Scheme     = "UsernamePassword"
            Parameters = @{
                Username = "***"
                P...
            }
        }
        Data = @{
            Environment = "Public"
        }
    }

    $workspaceName = "***"
    $workspaceId = "***"
    $fileName = "***"
    $userUpn = "***"
    $groupId = "***"
#>

If (!(test-path ".\Config\config.ps1")) {
    throw @"
TEST ISSUE - mke sure you have the following file with the correct template
    ~\Tasks\Tests\Config\config.ps1
"@
}

Get-ChildItem -Filter *.ps1 .\TestCases | Foreach-Object {
    try {
        $testName = $_
        Write-Host "Running Test: $_"

        & ".\TestCases\$_"

        Write-Host "Completed running Test: $_"
    }
    catch {
        Write-Error "Test ($testName) Failed with: $_"
        throw
    }
}