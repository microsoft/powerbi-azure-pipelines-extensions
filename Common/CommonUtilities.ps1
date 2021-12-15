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

		Connect-PowerBIServiceAccount -Environment $environment -Tenant $tenantId -Credential $credential -ServicePrincipal | Out-Null
	}
	elseif ($authScheme -eq "UsernamePassword") {
		$username = $authParams.Username
		$password = ConvertTo-SecureString $authParams.Password -AsPlainText -Force
		$credential = New-Object System.Management.Automation.PSCredential $username, $password

		Connect-PowerBIServiceAccount -Environment $environment -Credential $credential | Out-Null
	}
	else {
		Write-Error "Unsupported connection"
	}
}

function Invoke-PowerBIApi {
	param (
		[Guid] $ActivityId,
		[string] $Url,
		[string] $Method,
		[string] $Body
	)

	$headers = @{
		'ActivityId' = $ActivityId
	}

	return Invoke-PowerBIRestMethod -Url $Url -Method $Method -Headers $headers -Body $Body
}

function Get-Pipeline {
	param (
		[string] $Pipeline,
		[Guid] $ActivityId
	)

	# Get all pipelines
	$pipelines = (Invoke-PowerBIApi -ActivityId $ActivityId -Url "pipelines" -Method Get | ConvertFrom-Json).value

	# Try to find the pipeline by display name
	$foundPipeline = $pipelines | Where-Object { $_.DisplayName -eq $Pipeline }

	if (!$foundPipeline) {
		# Couldn't find pipeline by name, trying by Id
		$foundPipeline = $pipelines | Where-Object { $_.Id -eq $Pipeline }

		if (!$foundPipeline) {
			Write-Error "A pipeline with the requested name or Id was not found"
		}
	}

	return $foundPipeline
}

function Get-Workspace {
	param (
		[string] $Workspace,
		[Guid] $ActivityId
	)

	# Get all workspaces
	$workspaces = (Invoke-PowerBIApi -ActivityId $ActivityId -Url "groups" -Method Get | ConvertFrom-Json).value

	# Try to find the workspace by display name
	$foundWorkspace = $workspaces | Where-Object { $_.Name -eq $Workspace }

	if (!$foundWorkspace) {
		# Couldn't find workspace by name, trying by Id
		$foundWorkspace = $workspaces | Where-Object { $_.Id -eq $Workspace }

		if (!$foundWorkspace) {
			Write-Error "A workspace with the requested name or Id was not found"
		}
	}

	return $foundWorkspace
}
