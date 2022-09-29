Copy-Item -Recurse -Force -Path .\PowerBIApiUtils -Destination .\Common\ps_modules

Get-ChildItem -Directory .\Tasks | Foreach-Object {
    Copy-Item .\Icons\icon.png .\Tasks\$_\icon.png
    Copy-Item -Recurse -Force -Path .\Common\* -Destination .\Tasks\$_
}