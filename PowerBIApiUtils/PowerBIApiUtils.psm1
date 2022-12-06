Write-Host "Importing module MicrosoftPowerBIMgmt.Profile"
Import-Module .\ps_modules\MicrosoftPowerBIMgmt.Profile

function Connect-PowerBIService {
    param (
        $PbiConnection
    )

    $authScheme = $PbiConnection.Auth.Scheme
    $authParams = $PbiConnection.Auth.Parameters
    $environment = $PbiConnection.Data.Environment

    Write-Host "Connecting to Power BI with $authScheme"

    if ($authScheme -eq "ServicePrincipal") {
        $tenantId = $authParams.TenantId
        $clientId = $authParams.Serviceprincipalid

        $clientSecret = ConvertTo-SecureString $authParams.Serviceprincipalkey -AsPlainText -Force
        $credential = New-Object System.Management.Automation.PSCredential $clientId, $clientSecret

        $env = Connect-PowerBIServiceAccount -Environment $environment -Tenant $tenantId -Credential $credential -ServicePrincipal
        return $env.Environment.GlobalServiceEndpoint
    }
    elseif ($authScheme -eq "UsernamePassword") {
        $username = $authParams.Username
        $password = ConvertTo-SecureString $authParams.Password -AsPlainText -Force
        $credential = New-Object System.Management.Automation.PSCredential $username, $password

        $env = Connect-PowerBIServiceAccount -Environment $environment -Credential $credential
        return $env.Environment.GlobalServiceEndpoint
    }
    else {
        throw "Unsupported connection"
    }
}

function Invoke-PowerBIApi {
    param (
        [Guid] $ActivityId,
        [string] $Endpoint,
        [string] $Url,
        [string] $Method,
        [string] $Body
    )

    $accessToken = Get-PowerBIAccessToken -AsString

    $headers = @{
        'ActivityId'    = $ActivityId
        'User-Agent'    = "AzureDevOpsExtension"
        'Authorization' = $accessToken
    }

    $uri = "{0}/v1.0/myorg/{1}" -f $Endpoint, $Url

    Write-Host "Sending $Method request to - $uri"

    try {
        if (!$Body) {
            return Invoke-RestMethod -Uri $uri -Method $Method -Headers $headers
        }
        else {
            $headers['Content-Type'] = "application/json"
            Write-Host "Request Body: $Body"
            return Invoke-RestMethod -Uri $uri -Method $Method -Headers $headers -Body $Body
        }
    }
    catch {
        if ($_.Exception.Response) {
            $requestId = $_.Exception.Response.Headers.Get("RequestId")

            $result = $_.Exception.Response.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($result)
            $reader.BaseStream.Position = 0
            $reader.DiscardBufferedData()
            $responseBody = $reader.ReadToEnd();

            Write-Error @"
$_.Exception
    Request Id: $requestId
    Error response body:
        $responseBody
"@
        }

        throw
    }
}

function Get-Pipeline {
    param (
        [Guid] $ActivityId,
        [string] $Endpoint,
        [string] $Pipeline
    )

    Write-Host "Getting pipeline: $Pipeline"

    # Get all pipelines
    $pipelines = (Invoke-PowerBIApi -ActivityId $ActivityId -Endpoint $Endpoint -Url "pipelines" -Method Get).value

    # Try to find the pipeline by display name
    $foundPipeline = $pipelines | Where-Object { $_.DisplayName -eq $Pipeline }

    if (!$foundPipeline) {
        # Couldn't find pipeline by name, trying by Id
        $foundPipeline = $pipelines | Where-Object { $_.Id -eq $Pipeline }

        if (!$foundPipeline) {
            throw "A pipeline with the requested name or Id was not found"
        }
    }

    return $foundPipeline
}

function Get-Workspace {
    param (
        [Guid] $ActivityId,
        [string] $Endpoint,
        [string] $Workspace
    )

    Write-Host "Getting workspace: $Workspace"

    # Get all workspaces
    $workspaces = (Invoke-PowerBIApi -ActivityId $ActivityId -Endpoint $Endpoint -Url "groups" -Method Get).value

    # Try to find the workspace by display name
    $foundWorkspace = $workspaces | Where-Object { $_.Name -eq $Workspace }

    if (!$foundWorkspace) {
        # Couldn't find workspace by name, trying by Id
        $foundWorkspace = $workspaces | Where-Object { $_.Id -eq $Workspace }

        if (!$foundWorkspace) {
            throw "A workspace with the requested name or Id was not found"
        }
    }

    return $foundWorkspace
}

function New-Pipeline {
    param (
        [Guid] $ActivityId,
        [string] $Endpoint,
        [string] $DisplayName,
        [string] $Description
    )

    try {
        $body = @{
            displayName = $DisplayName
            description = $Description
        } | ConvertTo-Json

        $newPipeline = Invoke-PowerBIApi -ActivityId $ActivityId -Endpoint $Endpoint -Url "pipelines" -Method Post -Body $body

        Write-Host "New deployment pipeline created successfully - Id = $($newPipeline.Id)"
    }
    catch {
        $err = Resolve-PowerBIError -Last
        Write-Error $err.Message

        throw
    }
}

function Remove-Pipeline {
    param (
        [Guid] $ActivityId,
        [string] $Endpoint,
        [string] $Pipeline
    )

    try {
        $foundPipeline = Get-Pipeline -ActivityId $ActivityId -Endpoint $Endpoint -Pipeline $Pipeline

        $url = "pipelines/{0}" -f $foundPipeline.Id
        Invoke-PowerBIApi -ActivityId $ActivityId -Endpoint $Endpoint -Url $url -Method Delete

        Write-Host "Pipeline deleted successfully"
    }
    catch {
        $err = Resolve-PowerBIError -Last
        Write-Error $err.Message
        
        throw
    }
}

function Add-UserToPipeline {
    param (
        [Guid] $ActivityId,
        [string] $Endpoint,
        [string] $Pipeline,
        [string] $UserUpn
    )

    try {
        $foundPipeline = Get-Pipeline -ActivityId $ActivityId -Endpoint $Endpoint -Pipeline $Pipeline

        $url = "pipelines/{0}/users" -f $foundPipeline.Id
        $body = @{
            identifier    = $UserUpn
            accessRight   = "Admin"
            principalType = "User"
        } | ConvertTo-Json

        Invoke-PowerBIApi -ActivityId $ActivityId -Endpoint $Endpoint -Url $url -Method Post -Body $body

        Write-Host "User has been added to pipeline successfully"
    }
    catch {
        $err = Resolve-PowerBIError -Last
        Write-Error $err.Message
        
        throw
    }
}

function Add-UserToWorkspace {
    param (
        [Guid] $ActivityId,
        [string] $Endpoint,
        [string] $Workspace,
        [string] $UserUpn,
        [string] $Permission
    )

    try {
        $foundWorkspace = Get-Workspace -ActivityId $ActivityId -Endpoint $Endpoint -Workspace $Workspace

        $url = "groups/{0}/users" -f $foundWorkspace.Id
        $body = @{
            identifier           = $UserUpn
            groupUserAccessRight = $Permission
            principalType        = "User"
        } | ConvertTo-Json

        Invoke-PowerBIApi -ActivityId $ActivityId -Endpoint $Endpoint -Url $url -Method Post -Body $body

        Write-Host "User has been added to workspace successfully"
    }
    catch {
        $err = Resolve-PowerBIError -Last
        Write-Error $err.Message
        
        throw
    }
}

function Add-WorkspaceToPipeline {
    param (
        [Guid] $ActivityId,
        [string] $Endpoint,
        [string] $Pipeline,
        [int] $StageOrder,
        [string] $Workspace
    )

    try {
        $foundPipeline = Get-Pipeline -ActivityId $ActivityId -Endpoint $Endpoint -Pipeline $Pipeline

        $foundWorkspace = Get-Workspace -ActivityId $ActivityId -Endpoint $Endpoint -Workspace $Workspace

        $url = "pipelines/{0}/stages/{1}/assignWorkspace" -f $foundPipeline.Id, $StageOrder
        $body = @{
            workspaceId = $foundWorkspace.Id
        } | ConvertTo-Json

        Invoke-PowerBIApi -ActivityId $ActivityId -Endpoint $Endpoint -Url $url -Method Post -Body $body

        Write-Host "Workspace has been assigned to pipeline successfully"
    }
    catch {
        $err = Resolve-PowerBIError -Last
        Write-Error $err.Message
        
        throw
    }
}

function Remove-WorkspaceFromPipeline {
    param (
        [Guid] $ActivityId,
        [string] $Endpoint,
        [string] $Pipeline,
        [int] $StageOrder
    )

    try {
        $foundPipeline = Get-Pipeline -ActivityId $ActivityId -Endpoint $Endpoint -Pipeline $Pipeline

        $url = "pipelines/{0}/stages/{1}/unassignWorkspace" -f $foundPipeline.Id, $StageOrder

        Invoke-PowerBIApi -ActivityId $ActivityId -Endpoint $Endpoint -Url $url -Method Post

        Write-Host "Workspace has been assigned to pipeline successfully"
    }
    catch {
        $err = Resolve-PowerBIError -Last
        Write-Error $err.Message
        
        throw
    }
}

function Initialize-ArtifactsForDeployment {
    param (
        [string] $RequestedArtifacts,
        $Artifacts,
        [string] $Type
    )

    $result = @()
    foreach ($artifact in $RequestedArtifacts.Split(";")) {
        $artifact = $artifact.Trim()

        if ($artifact) {
            $foundArtifact = $Artifacts | Where-Object { $_.artifactDisplayName -eq $artifact }

            if (!$foundArtifact) {
                $foundArtifact = $Artifacts | Where-Object { $_.artifactId -eq $artifact }

                if (!$foundArtifact) {
                    throw "A $Type with the requested name or Id was not found - ($artifact)"
                }
            }

            $result = $result + @{ sourceId = $foundArtifact.artifactId }
        }
    }

    return (, $result)
}

function Start-PipelineDeployment {
    param (
        [Guid] $ActivityId,
        [string] $Endpoint,
        [string] $Pipeline,
        [string] $StageOrder,
        [string] $Note,
        [bool] $WaitForCompletion,
        [string] $DeployType,
        [string] $Dataflows,
        [string] $Datamarts,
        [string] $Datasets,
        [string] $Reports,
        [string] $Dashboards,
        [bool] $CreateNewWS,
        [string] $NewWsName,
        [string] $Capacity,
        [bool] $AllowCreateArtifact,
        [bool] $AllowOverwriteArtifact,
        [bool] $AllowOverwriteTargetArtifactLabel,
        [bool] $AllowPurgeData,
        [bool] $AllowSkipTilesWithMissingPrerequisites,
        [bool] $AllowTakeOver,
        [bool] $UpdateApp
    )

    try {
        $foundPipeline = Get-Pipeline -ActivityId $ActivityId -Endpoint $Endpoint -Pipeline $Pipeline

        # Prepare the request body
        switch ($StageOrder) {
            "Test" {
                $body = @{
                    sourceStageOrder     = 0
                    isBackwardDeployment = $FALSE
                }
            }

            "Production" {
                $body = @{
                    sourceStageOrder     = 1
                    isBackwardDeployment = $FALSE
                }
            }

            "Development (Backward)" {
                $body = @{
                    sourceStageOrder     = 1
                    isBackwardDeployment = $TRUE
                }
            }

            "Test (Backward)" {
                $body = @{
                    sourceStageOrder     = 2
                    isBackwardDeployment = $TRUE
                }
            }
        }

        $body.options = @{
            # Allows creating new artifact if needed on the Test stage workspace
            allowCreateArtifact                    = $AllowCreateArtifact
            # Allows overwriting existing artifact if needed on the Test stage workspace
            allowOverwriteArtifact                 = $AllowOverwriteArtifact
            allowOverwriteTargetArtifactLabel      = $AllowOverwriteTargetArtifactLabel
            allowPurgeData                         = $AllowPurgeData
            allowSkipTilesWithMissingPrerequisites = $AllowSkipTilesWithMissingPrerequisites
            allowTakeOver                          = $AllowTakeOver
        }

        $body.note = $Note

        if ($CreateNewWS) {
            $body.newWorkspace = @{
                name       = $NewWsName
                capacityId = $Capacity
            }
        }

        if ($UpdateApp) {
            $body.updateAppSettings = @{
                updateAppInTargetWorkspace = $TRUE
            }
        }

        if ($DeployType -eq "Selective") {
            $artifactsUrl = "pipelines/{0}/stages/{1}/artifacts" -f $foundPipeline.Id, $body.sourceStageOrder
            $artifacts = Invoke-PowerBIApi -ActivityId $ActivityId -Endpoint $Endpoint -Url $artifactsUrl -Method Get

            $body.dataflows = Initialize-ArtifactsForDeployment -RequestedArtifacts $Dataflows -Artifacts $artifacts.dataflows -Type "dataflow"
            $body.datamarts = Initialize-ArtifactsForDeployment -RequestedArtifacts $Datamarts -Artifacts $artifacts.datamarts -Type "datamart"            
            $body.datasets = Initialize-ArtifactsForDeployment -RequestedArtifacts $Datasets -Artifacts $artifacts.datasets -Type "dataset"
            $body.reports = Initialize-ArtifactsForDeployment -RequestedArtifacts $Reports -Artifacts $artifacts.reports -Type "reports"
            $body.dashboards = Initialize-ArtifactsForDeployment -RequestedArtifacts $Dashboards -Artifacts $artifacts.dashboards -Type "dashboard"

            $deployUrl = "pipelines/{0}/Deploy" -f $foundPipeline.Id
        }
        else {
            $deployUrl = "pipelines/{0}/DeployAll" -f $foundPipeline.Id
        }

        $body = $body | ConvertTo-Json

        $deployResult = Invoke-PowerBIApi -ActivityId $ActivityId -Endpoint $Endpoint -Url $deployUrl -Method Post -Body $body

        Write-Host "Deployment requested sucessfully, Operation ID: $($deployResult.id)"

        if (!$WaitForCompletion) {
            Write-Host "Skipping wait for deployment job completion"
            return
        }

        # Get the deployment operation details
        $operationUrl = "pipelines/{0}/Operations/{1}" -f $foundPipeline.Id, $deployResult.id
        $operation = Invoke-PowerBIApi -ActivityId $ActivityId -Endpoint $Endpoint -Url $operationUrl -Method Get

        while ($operation.Status -eq "NotStarted" -or $operation.Status -eq "Executing") {
            Write-Host "Waiting for deployment completion, Status = $($operation.Status)"
            # Sleep for 5 seconds
            Start-Sleep -s 5

            $operation = Invoke-PowerBIApi -ActivityId $ActivityId -Endpoint $Endpoint -Url $operationUrl -Method Get
        }

        $message = "Deployment completed with status: {0}, Operation Id: {1}" -f $operation.Status, $deployResult.id
        if ($operation.Status -ne "Succeeded") {
            Write-Error $message
        }
        else {
            Write-Host $message
        }
    }
    catch {
        $err = Resolve-PowerBIError -Last
        Write-Error $err.Message

        throw
    }
}

Export-ModuleMember -Function *