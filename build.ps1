Param(
    [switch]$Prod,
    [switch]$SkipModules,
    [switch]$UpdateVersion
)

# install modules
if (!$SkipModules) {
    .\build\InstallRequiredModules.ps1 -ModulesConfigPath .\config\modules.json
}

# copy common files to each task
.\build\CopyCommonFiles.ps1

if ($Prod) { 
    $ovverides = 'config\prod.json' 
}
else {
    $ovverides = 'config\dev.json'
}

# packge extension
tfx extension create --overrides-file $ovverides --rev-version $UpdateVersion --output-path vsix