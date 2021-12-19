Param(
    [string] $ModulesConfigPath
)


$tempModulesPath = ".\Common\temp"
$modulesPath = ".\Common\ps_modules"

If (!(test-path $tempModulesPath)) {
    New-Item -Path $tempModulesPath -ItemType Directory -Force
}

$configRaw = Get-Content -Path $ModulesConfigPath -Raw
$modules = $configRaw | ConvertFrom-Json

$modules.modules | Foreach-Object {
    Save-Module -Name $_.name -RequiredVersion $_.version -Path $tempModulesPath

    $sourcePath = "{0}\{1}\{2}" -f $tempModulesPath, $_.name, $_.version
    $targetPath = "{0}\{1}" -f $modulesPath, $_.name

    If (test-path $targetPath) {
        Remove-Item -Path $targetPath -Recurse -Force
    }
    
    Copy-Item -Recurse -Force -Path $sourcePath -Destination $targetPath   
}

Remove-Item -Path $tempModulesPath -Recurse -Force