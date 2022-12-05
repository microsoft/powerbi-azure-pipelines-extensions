Param(
    [switch]$Prod,
    [switch]$SkipModules,
    [switch]$UpdateVersion,
    [switch]$RunTests
)

# install modules
if (!$SkipModules) {
    .\build\InstallRequiredModules.ps1 -ModulesConfigPath .\config\modules.json
}

# copy common files to each task
.\build\CopyCommonFiles.ps1

# run tests
if ($RunTests) {
    Push-Location .\Tasks\Tests

    try {
        .\RunAllTests.ps1
    }
    catch {
        throw "Tests Failed"
    }
    finally {        
        Pop-Location
    }
}

if ($Prod) { 
    $ovverides = 'config\prod.json' 
}
else {
    $ovverides = 'config\dev.json'
}

# packge extension
tfx extension create --overrides-file $ovverides --rev-version $UpdateVersion --output-path vsix
