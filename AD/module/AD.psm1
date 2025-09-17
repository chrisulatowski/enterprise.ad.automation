# Import all functions from the Functions folder and its subfolders
$functionPath = Join-Path $PSScriptRoot 'functions/**/*.ps1'
Get-ChildItem -Path $functionPath -File -Recurse | ForEach-Object {
    . $_.FullName
}
