Param(
    $Modules
)

$tempModulesPath = ".\Common\temp"
$modulesPath = ".\Common\ps_modules"

If (!(test-path $tempModulesPath)) {
    New-Item -Path $tempModulesPath -ItemType Directory -Force
}

$Modules | Foreach-Object {
    Save-Module -Name $_.name -RequiredVersion $_.version -Path $tempModulesPath

    $sourcePath = "{0}\{1}\{2}" -f $tempModulesPath, $_.name, $_.version
    $targetPath = "{0}\{1}" -f $modulesPath, $_.name

    Copy-Item -Recurse -Force -Path $sourcePath -Destination $targetPath   
}

Remove-Item -Path $tempModulesPath -Recurse -Force