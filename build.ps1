Param(
    [switch]$Prod,
    [switch]$UpdateVersion,
    [switch]$Package
)

$configPath = "config.json"
$configRaw = Get-Content -Path $configPath -Raw
$config = $configRaw | ConvertFrom-Json

# install modules
.\build\InstallRequiredModules.ps1 -Modules $config.modules

# copy common files to each task
.\build\CopyCommonFiles.ps1

# update extension version in config file
$version = [version]$config.version
$increment = if ($UpdateVersion) { 1 } else { 0 }
$newVersion = "{0}.{1}.{2}" -f $version.Major, $version.Minor, ($version.Build + $increment)
$configRaw = $configRaw.Replace($config.version, $newVersion)
Set-Content -Value $configRaw -Path $configPath -NoNewline

# set extension mising properties in extension json (id, version, public)
$env = if ($Prod) { $config.prod } else { $config.dev }

$extension = Get-Content vss-extension-template.json -raw

$newExtension = $extension.Replace('EXTENSION_ID', $env.id)
$newExtension = $newExtension.Replace('EXTENSION_VERSION', $newVersion)
$newExtension = $newExtension.Replace('"EXTENSION_PUBLIC"', $env.public)

# create extesnion json file
Set-Content -Value $newExtension -Path vss-extension.json -NoNewline

# packge extension
if ($Package) {
    tfx extension create --manifest-globs $newExtensionPath
}