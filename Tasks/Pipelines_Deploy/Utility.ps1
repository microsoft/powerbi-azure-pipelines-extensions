function Proccess-Artifacts {
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
                    Write-Error "A $Type with the requested name or Id was not found - ($artifact)" 

                    return
                }
            }

            $result = $result + @{ sourceId = $foundArtifact.artifactId }
        }
    }

    return $result
}