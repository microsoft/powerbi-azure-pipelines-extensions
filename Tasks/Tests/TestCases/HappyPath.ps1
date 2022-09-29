function TestHappyPath {
    param (
        [bool] $ByDisplayName
    )

    . .\InitTask.ps1

    $displayName = "test pipeline $activityId"
    $description = "test pipeline $activityId (happy path)"

    Write-Host "Create a new pipeline with name ($displayName)"

    New-Pipeline -ActivityId $activityId -Endpoint $endpoint -DisplayName $displayName -Description $description

    Write-Host "Get the newly created pipeline"

    $testPipeline = Get-Pipeline -ActivityId $activityId -Endpoint $endpoint -Pipeline $displayName
    $pipelineId = $testPipeline.Id
    if ($testPipeline.DisplayName -ne $displayName -or $testPipeline.Description -ne $description) {
        throw "Created pipeline ($testPipeline) expected to be with displayName=($displayName) and description=($description)"
    }

    if ($ByDisplayName) {
        $pipeline = $displayName
    }
    else {
        $pipeline = $testPipeline.Id
    }    

    Write-Host "Add user ($userUpn) to the pipeline"

    Add-UserToPipeline -ActivityId $activityId -Endpoint $endpoint -Pipeline $pipeline -UserUpn $userUpn
    $users = (Invoke-PowerBIApi -ActivityId $ActivityId -Endpoint $Endpoint -Url "pipelines/$pipelineId/users" -Method Get).value
    $foundUser = $users | Where-Object { $_.Identifier -eq $userUpn }
    if (!$foundUser -or $foundUser.AccessRight -ne "Admin") {
        throw "Expected to user $userUpn to be pipeline admin. found=($foundUser)"
    }

    Write-Host "Assign workspace ($workspaceName) to development stage"

    Add-WorkspaceToPipeline -ActivityId $activityId -Endpoint $endpoint -Pipeline $pipeline -StageOrder 0 -Workspace $workspaceName
    $stages = (Invoke-PowerBIApi -ActivityId $ActivityId -Endpoint $Endpoint -Url "pipelines/$pipelineId/stages" -Method Get).value
    $devStage = $stages | Where-Object { $_.order -eq 0 }
    if (!$devStage -or $devStage.WorkspaceId -ne $workspaceId) {
        throw "Expected development stage to have workpsace $workspaceId but found ($devStage)"
    }

    Write-Host "Start full deployment to the test stage"

    $testWorkspaceName = "$workspaceName [Test]"
    Start-PipelineDeployment -ActivityId $activityId -Endpoint $endpoint -Pipeline $pipeline -StageOrder "Test"-WaitForCompletion $TRUE -DeployType "All" -CreateNewWS $TRUE -NewWsName $testWorkspaceName -AllowCreateArtifact $TRUE -AllowOverwriteArtifact $TRUE
    $stages = (Invoke-PowerBIApi -ActivityId $ActivityId -Endpoint $Endpoint -Url "pipelines/$pipelineId/stages" -Method Get).value
    $testStage = $stages | Where-Object { $_.order -eq 1 }
    if (!$testStage -or !($testStage.WorkspaceId)) {
        throw "Expected test stage to have a workpsace but found ($testStage)"
    }

    Write-Host "Add user ($userUpn) to the test workspace"

    Add-UserToWorkspace -ActivityId $activityId -Endpoint $endpoint -Workspace $testWorkspaceName -UserUpn $userUpn -Permission "Admin"

    Write-Host "Start selective deployment to the production stage with dataflow, datamart, dataset, report and dashboard named ($fileName)"

    $prodWorkspaceName = "$workspaceName [Production]"
    Start-PipelineDeployment -ActivityId $activityId -Endpoint $endpoint -Pipeline $pipeline -StageOrder "Production" -WaitForCompletion $TRUE -DeployType "Selective" -Dataflow $fileName -Datamart $fileName -Datasets $fileName -Reports $fileName -Dashboards $fileName -CreateNewWS $TRUE -NewWsName $prodWorkspaceName -AllowCreateArtifact $TRUE -AllowOverwriteArtifact $TRUE 
    $stages = (Invoke-PowerBIApi -ActivityId $ActivityId -Endpoint $Endpoint -Url "pipelines/$pipelineId/stages" -Method Get).value
    $prodStage = $stages | Where-Object { $_.order -eq 2 }
    if (!$prodStage -or !($prodStage.WorkspaceId)) {
        throw "Expected production stage to have a workpsace but found ($prodStage)"
    }

    Write-Host "Unassign all workspaces from pipeline"
    $stages | Foreach-Object {
        Remove-WorkspaceFromPipeline -ActivityId $activityId -Endpoint $endpoint -Pipeline $pipeline -StageOrder $_.order

        if ($_.order -ne 0) {
            $workspaceId = $_.workspaceId
            Invoke-PowerBIApi -ActivityId $ActivityId -Endpoint $Endpoint -Url "groups/$workspaceId" -Method Delete
        }
    }

    $stages = (Invoke-PowerBIApi -ActivityId $ActivityId -Endpoint $Endpoint -Url "pipelines/$pipelineId/stages" -Method Get).value
    $assignedStages = $stages | Where-Object { $_.WorkspaceId }
    if ($assignedStages) {
        throw "Expected all stages to be without workspaces but found ($stages)"
    }

    Write-Host "Delete pipeline"
    Remove-Pipeline -ActivityId $activityId -Endpoint $endpoint -Pipeline $pipeline
    $pipelines = (Invoke-PowerBIApi -ActivityId $ActivityId -Endpoint $Endpoint -Url "pipelines" -Method Get).value
    $deletedPipeline = $pipelines | Where-Object { $_.Id -eq $pipelineId }
    if ($deletedPipeline) {
        throw "Expected pipeline to be deleted but found ($deletedPipeline)"
    }
}

. .\Config\config.ps1

TestHappyPath -ByDisplayName $false

TestHappyPath -ByDisplayName $true